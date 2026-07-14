# ont-multiomics-nf

Long-read (Oxford Nanopore) multi-omics pipeline: align/sort, QC, SNV
(Clair3), SV (Sniffles2), STR (Straglr), CNV (mosdepth + Spectre) and
methylation (modkit) calling.

## Layout

```
ont-multiomics-nf/
├── main.nf                     # Entry point -- kept intentionally tiny
├── nextflow.config             # Default params, profiles, reporting
├── conf/
│   └── base.config             # Per-process cpus/memory
├── workflows/
│   └── ont_multiomics.nf       # Wires the modules together, --analysis logic
└── modules/
    └── local/
        ├── align.nf            # minimap2 (not wired in yet, see below)
        ├── sort_index.nf       # samtools sort + index
        ├── qc.nf                # samtools flagstat/stats
        ├── snv.nf               # Clair3
        ├── sv.nf                # Sniffles2
        ├── str.nf               # Straglr
        ├── mosdepth.nf          # coverage, feeds CNV
        ├── cnv.nf                # Spectre
        ├── modkit.nf            # methylation pileup
        └── report.nf            # text aggregator (not wired in yet)
```

## Why this split

- **`main.nf`** only validates that you gave it something to run on, then
  calls the workflow. Nothing else lives here, so it stays readable.
- **`workflows/ont_multiomics.nf`** is the recipe: given `--analysis`, it
  decides which processes actually run and how outputs feed into each
  other (e.g. `MOSDEPTH` -> `CNV`).
- **`modules/local/*.nf`** each hold exactly one process (the nf-core
  convention). It makes it obvious where to look when, say, Clair3's
  command line needs tweaking, and a process can be reused in a
  different workflow later without dragging the rest along.
- **`conf/base.config`** centralises `cpus`/`memory` so resources can be
  retuned per environment (laptop vs cluster) without touching process
  logic.

## Running it

```bash
nextflow run main.nf \
    --bam 'data/*_sorted.bam' \
    --reference genome.fa \
    --analysis 'qc,snv,sv,cnv,methylation' \
    --outdir results \
    -profile docker
```

`timeline`/`report`/`trace`/`dag` are already turned on in
`nextflow.config`, so `results/pipeline_info/` will have an actual
execution DAG and timing report after every run -- no need to remember
`-with-dag` etc. by hand.

Sample IDs come from the part of the BAM filename before the first `_`
(`sampleA_sorted.bam` -> `sampleA`), same as the original -- just calling
that out since it's an easy naming gotcha to hit.

## Bugs fixed while splitting this up

Flagging these clearly since they change behaviour vs. the original file:

1. **`QC`** declared a single `path bam` input but was called with the
   `(sample_id, bam, bai)` tuple every other process uses -- that
   mismatch would fail at run time. Fixed the input signature, and added
   a `publishDir` + per-sample output name (originally QC published
   nothing, and every sample would have written the same `qc.txt`).
2. **`SV`** was missing a line-continuation backslash after
   `--reference $ref`, so `sniffles` ran without `--snf`, and the shell
   then tried (and failed) to execute `--snf sample_sv.snf` as its own
   command.
3. **`CNV` outputs** -- a missing comma meant the last two paths were a
   separate second output instead of part of the same tuple. Combined
   into one 4-element tuple.
4. **`--analysis` parsing** -- the original matched with `.contains()` on
   the raw, un-split string, so `--analysis QC` (capitalised) silently
   matched nothing, and there was no whitespace trimming. Replaced with a
   proper split/trim/lowercase into a list -- this is what the
   commented-out line at the top of the original file was clearly trying
   to do.
5. **`mosdepth` -> `MOSDEPTH`** -- renamed for consistency; every other
   process is upper-case.
6. Minor: unified `publishDir` string interpolation
   (`${params.outdir}` everywhere -- `modkit` used `$params.outdir`), and
   `MODKIT`'s reference input renamed `reference` -> `ref` to match its
   siblings.
7. Added `checkIfExists: true` to `Channel.fromPath(params.bam, ...)`, so
   a typo'd `--bam` glob fails fast with a clear error instead of
   silently running zero samples.

## Left exactly as-is (worth your attention, not changed)

- **`ALIGN`** (FASTQ/pod5 entry point) is preserved in
  `modules/local/align.nf` but **not called** -- the active pipeline only
  starts from `--bam`, same as the original `workflow {}` block actually
  did (the FASTQ/pod5 branch was commented out there too). Say the word
  if you want that entry point wired back in.
- **`REPORT`** is fully written but was never invoked in the original
  either, so it's carried over unwired in `modules/local/report.nf`. It
  takes single (not `.collect()`-ed) paths, so it needs a small rework
  for a combined multi-sample report.
- **`MOSDEPTH` and `CNV` both use the `spectre:0.2.1` container.** Left
  exactly as it was -- if that image bundles mosdepth intentionally,
  great; otherwise worth a second look.
- **`params.threads`** (default `8`) is declared but nothing reads it --
  every process sets its own `cpus`, now in `conf/base.config`. Left as
  a no-op since I didn't want to guess whether you want it wired up
  globally or dropped.
- No new resource limits were invented anywhere -- `conf/base.config`
  only relocates the `cpus`/`memory` values that were already hardcoded
  in the original. `ALIGN`, `QC` and `REPORT` had none originally and
  still don't.

## Possible next steps (not done, just flagging)

- `nextflow_schema.json` + `-help` for self-documenting parameters.
- Move `container`/`publishDir` into `conf/modules.config` too, if you
  want fully config-driven modules.
- `nf-test` unit tests per module.
