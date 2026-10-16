---
hide:
  - toc
---

# Data

Three CSV files, all linked by `subject_id`, all generated together by
[`data/generate_datasets.ipynb`](https://github.com/SanCamilloIRCCS-OndaLab/tutorial_EEG-NPSY/tree/main/data):

| File | Type | Columns | Used by |
|---|---|---|---|
| `dataset_NPSY.csv` | <span class="data-badge data-badge--synthetic">Synthetic</span> | `age`, `sex`, `criq`, `apacs`, `att_matr`, `moca` | Case Study 1 & 2 |
| `dataset_ERP.csv` | <span class="data-badge data-badge--synthetic">Synthetic</span> | `n400_amp`, `n400_lat`, `p300_amp`, `p300_lat` | Case Study 1 |
| `dataset_PSD.csv` | <span class="data-badge data-badge--real">Real</span> | `mean_power`, `delta_power`, `theta_power`, `alpha_power`, `beta_power`, `gamma_power` | Case Study 2 (summary only — the real analysis uses the full arrays below) |

Each file has 45 rows (46 with the header): 40 clean participants used
in the final analyses, plus 5 deliberately added with missing or
implausible values, so each case study has something real to detect and
exclude (see its **Data Wrangling** section). The audit trail
(`data/EEG/PSD/subject_id_mapping.csv`) flags these five with a `-dup`
suffix, since they are duplicated spectra rather than independent
recordings.

## What's synthetic and what's real

<div class="grid cards" markdown>

-   :material-flask-outline:{ .lg .middle } **Synthetic**

    ---

    `dataset_NPSY.csv` and `dataset_ERP.csv` are entirely invented — so
    that the associations each case study demonstrates are known in
    advance, and so the tutorial can be run end to end without real
    patient data.

-   :material-waveform:{ .lg .middle } **Real**

    ---

    Case Study 2's EEG spectra are real, anonymised recordings from the
    PATHS study (`data/EEG/PSD/psd_matrix.npy`, `psd_log_matrix.npy`,
    computed by `data/EEG/PSD/compute_psd.ipynb` from real epoched
    recordings), authorised for publication here. Case Study 2 itself
    reads the `_full` variants of these two arrays
    (`psd_log_matrix_full.npy`, `psd_matrix_full.npy`), which also
    include the 5 duplicated spectra mentioned above — the original
    40-recording files are never modified.

</div>

!!! warning "Important disclosure"
    Because the real EEG and the synthetic neuropsychological table do
    not come from the same patients, the (synthetic) `moca` column was
    deliberately linked to a real, montage-based property of each
    recording. **The resulting brain–behaviour association in Case
    Study 2 should not be read as a real clinical finding** — see the
    notice at the top of `generate_datasets.ipynb` for the full
    disclosure.
