# Dataset provenance and version uncertainty

## Published origin

The supplied filenames and four contact-time annotations correspond to the controlled motorcycle experiment described by Boubezoul et al. [R1], collected with a motorcycle-mounted three-axis accelerometer and three-axis gyroscope at 1000 Hz. The publication provides data as supplementary files. It is the scientific dataset source; a prior software project is not the dataset citation.

A 2020 corrigendum [R2] reports that binary-to-ASCII conversion mixed Ay with another sensor and supplies corrected fall data in `mmc1.zip`. It also explains that three corrected fall recordings include post-fall lifting; the roundabout recording stops at the end of the fall. Consequently, a full recording is not a pure fall interval.

Official sources:

- Original data article and supplements: https://doi.org/10.1016/j.dib.2019.103828
- Corrected fall supplement and notice: https://doi.org/10.1016/j.dib.2020.105577

## Exact bytes included in this project

The ten CSV files were recovered from the user-supplied `V4_FINAL_MATLAB_R1.zip` data folders. That archive is a transfer container, not a scientific source. Its SHA-256 is `f4bbd88fdaf4c36208a8d484e53ba857cfdffe78f07f660d9699149cb02fac0d`.

CSV filenames were changed to English machine-safe keys. Their contents were copied byte-for-byte, including the original Latin-1 unit header and tab-separated numeric data despite the .csv extension. No Ay replacement, channel sign correction, resampling, clipping or prefix deletion was applied. `config/INPUT_MANIFEST.json` and `docs/INPUT_FILES.csv` give original filenames, complete SHA-256, sample counts and annotations.

**The included bytes have not been compared with the publisher's corrected ZIP. The corrected/original edition status is unresolved.** A filename suffix alone does not establish the edition. All records carry `upstream_byte_identity = NOT_VERIFIED_AGAINST_PUBLISHER_DOWNLOAD`. Numerical fit may reproduce a conversion error; it cannot validate that edition.

To resolve this before publication: obtain the official corrigendum supplement through its DOI, extract the four fall CSVs, compare actual channel data and lengths against these raw files, and document any verified replacement in a new input manifest/new run. Do not silently swap data inside an existing frozen run. The current project is runnable on the supplied bytes and transparently retains this limitation.

## Included records

| English key | Split | Original filename | Samples | Source-time range (s) |
|---|---|---|---:|---|
| fall_curve | BUILD | Fall in a curve_V1.csv | 78,461 | 0.001–78.461 |
| fall_roundabout | BUILD | Fall in the roundabout_V1.csv | 66,365 | 0.001–66.365 |
| fall_leaning | BUILD | Fall with leaning of the motorcycle_V1.csv | 81,663 | 0.001–81.663 |
| acceleration_straight | BUILD | Acceleration On Straight Line_V1.csv | 138,303 | 0.001–138.303 |
| harsh_braking_straight | BUILD | Harsh breaking On Straight Line_V1.csv | 111,485 | 0.001–111.485 |
| fall_like_1 | BUILD | Fall Like manoeuvre 1_V1.csv | 132,478 | 0.001–132.478 |
| fall_like_2 | BUILD | Fall Like manoeuvre 2_V1.csv | 148,926 | 0.001–148.926 |
| fall_slippery_straight | TEST | Fall on a slippery straight road section_V1.csv | 74,045 | 0.001–74.045 |
| acceleration_curve | TEST | Acceleration On Curve_V1.csv | 47,935 | 0.001–47.935 |
| fall_like_3 | TEST | Fall Like manoeuvre 3_V1.csv | 128,446 | 0.001–128.446 |

Total: 1,008,107 rows. Every file has a continuous 1 ms timestamp grid and 24 leading rows with all six IMU values zero. Those rows are retained and scored. The first timestamp is 0.001 s; the first nonzero sensor row is at 0.025 s. There are no NaN or infinite numeric values in the supplied files. This is a read-only raw-data audit, not a claim that every physical sensor value is valid.

## Labels and event intervals

`record_contains_fall` is a record-level description. It must not be used as a positive label for every sample of a full fall recording. The paper's T1 is crash-protector contact and T2 is the rider's hip contact, not an experimentally established onset of instability:

| Record | T1 (s) | T2 (s) |
|---|---:|---:|
| fall_curve | 43.486 | 43.756 |
| fall_roundabout | 35.876 | 36.160 |
| fall_leaning | 34.288 | 34.502 |
| fall_slippery_straight | 40.132 | 40.428 |

These source-time annotations are copied as metadata and video markers, never used to crop/align the reconstruction or tune its parameters. Applicability to a replacement edition must be rechecked. The six nonfall recordings have no invented fall interval. Augmentation retains timing and parent metadata but does not create an onset annotation that was absent.

## What was not supplied

No synchronized per-sample optical/GPS trajectory, independently measured initial speed, surveyed lever arm/mounting matrix, separate rider IMU, contact force or sensor full-scale calibration accompanies these ten CSVs. Published experimental descriptions and videos do not substitute for a numerical ground-truth trajectory in this project. The display geometry, gravity, mounting prior and bias assumptions are declared in PROJECT_CONFIG.
