"""Generate generate_mock_data.ipynb with latent-variable generative model."""
import nbformat as nbf

nb = nbf.v4.new_notebook()
nb.metadata = {
    "kernelspec": {"display_name": "eegnpsi", "language": "python", "name": "python3"},
    "language_info": {"name": "python", "version": "3.14.3"},
}

cells = []

def md(s):
    cells.append(nbf.v4.new_markdown_cell(s))

def code(s):
    cells.append(nbf.v4.new_code_cell(s))


# Title
md("""# Generate mock data -- Case Study 1

Synthetic dataset generation following the PATHS-inspired model:

> **Latent abilities** (language, attention) mediate the effect of
> lesion severity on both ERP markers and cognitive test scores.

### Generative structure

```
gravita_lesione, eta, sesso, criq, education
         |
         +---> abilita_linguaggio ---> n400_amp, n400_lat, apacs, moca
         +---> abilita_attenzione ---> p300_amp, p300_lat, matrici, moca
         +---> direct ---> all cognitive tests (skewed low)
```
""")

# Imports
md("## Imports")

code('\n'.join([
    "from pathlib import Path",
    "import numpy as np",
    "import pandas as pd",
    "import matplotlib.pyplot as plt",
    "import seaborn as sns",
    "from scipy.stats import zscore",
    "",
    "sns.set_style('whitegrid')",
    "print('All imports OK.')",
]))

# Helpers
md("## Helper functions")

code('\n'.join([
    "def standardize(x):",
    "    return (x - np.mean(x)) / np.std(x, ddof=1)",
    "",
    "def make_latent(grav, eta, rng, beta_grav=0.7, beta_eta=0.2, r2=0.5):",
    "    'Latent ability driven by lesion severity and age.'",
    "    z = -beta_grav * standardize(grav) - beta_eta * standardize(eta)",
    "    z_sys = z / np.std(z, ddof=1) * np.sqrt(r2)",
    "    z_noise = rng.normal(0, np.sqrt(1 - r2), len(z))",
    "    return z_sys + z_noise",
    "",
    "def make_linear_exact(predictors, betas, rng, r2):",
    "    '''Generate outcome with EXACT target regression betas and R2.",
    "",
    "    Uses orthogonal noise projection so that OLS of y on X recovers",
    "    exactly the specified betas with the specified R2 in every draw.",
    "    '''",
    "    X = np.column_stack([standardize(predictors[k]) for k in betas])",
    "    n, k = len(X), len(betas)",
    "    b = np.array([betas[k] for k in betas])",
    "    y_sys = X @ b",
    "    var_sys = np.var(y_sys, ddof=1)",
    "    if var_sys < 1e-12:",
    "        return rng.normal(0, 1, n)",
    "    var_total = var_sys / r2",
    "    var_noise = var_total - var_sys",
    "    Xc = np.column_stack([np.ones(n), X])",
    "    P = Xc @ np.linalg.inv(Xc.T @ Xc) @ Xc.T",
    "    noise_raw = rng.normal(0, 1, n)",
    "    noise_orth = noise_raw - P @ noise_raw",
    "    noise_orth = noise_orth / np.std(noise_orth, ddof=1) * np.sqrt(max(var_noise, 0))",
    "    return y_sys + noise_orth",
]))

# Parameters
md("## Parameters\n\nTweak these to control sample size, effect sizes, and distributions.")

code('\n'.join([
    "n = 60",
    "seed = 42",
    "",
    "# R2 targets",
    "R2_LATENT = 0.50",
    "R2_ERP    = 0.35",
    "R2_TEST   = 0.35",
    "",
    "# Education distribution",
    "edu_values = [5, 8, 13, 16, 18, 22]",
    "edu_p = [.10, .21, .34, .12, .15, .08]",
]))

# RNGs
md("## Random number generators (independent seeds)")

code('\n'.join([
    "rng_grav  = np.random.default_rng(seed)",
    "rng_eta   = np.random.default_rng(seed + 1)",
    "rng_edu   = np.random.default_rng(seed + 2)",
    "rng_sex   = np.random.default_rng(seed + 3)",
    "rng_criq  = np.random.default_rng(seed + 4)",
    "rng_ling  = np.random.default_rng(seed + 5)",
    "rng_attn  = np.random.default_rng(seed + 6)",
    "rng_n400a = np.random.default_rng(seed + 7)",
    "rng_n400l = np.random.default_rng(seed + 8)",
    "rng_p300a = np.random.default_rng(seed + 9)",
    "rng_p300l = np.random.default_rng(seed + 10)",
    "rng_apacs = np.random.default_rng(seed + 11)",
    "rng_matr  = np.random.default_rng(seed + 12)",
    "rng_moca  = np.random.default_rng(seed + 13)",
    "print('RNGs ready.')",
]))

# Step 1
md("## Step 1 -- Basic variables")

code('\n'.join([
    "# Right-skewed lesion severity: mild strokes more common",
    "gravita = rng_grav.exponential(scale=3, size=n)",
    "gravita = np.clip(gravita, 0, 15)",
    "",
    "eta = rng_eta.uniform(50, 80, n).round().astype(int)",
    "",
    "education = rng_edu.choice(edu_values, n, p=edu_p).astype(float)",
    "",
    "sesso = rng_sex.binomial(1, 0.5, n).astype(float)",
    "",
    "# CRIq ~ N(100, 15), corr with education (+0.3) and age (-0.15)",
    "z_criq = rng_criq.normal(0, 1, n)",
    "z_criq = z_criq + 0.30 * standardize(education) - 0.15 * standardize(eta)",
    "criq = 100 + 15 * standardize(z_criq)",
    "criq = np.clip(criq, 70, 130)",
    "del z_criq",
    "",
    "print(f'Basic variables: {n} subjects generated.')",
]))

# Step 2
md("## Step 2 -- Latent abilities (not exported)")

code('\n'.join([
    "abilita_linguaggio = make_latent(gravita, eta, rng_ling, r2=R2_LATENT)",
    "abilita_attenzione = make_latent(gravita, eta, rng_attn, r2=R2_LATENT)",
    "",
    "print(f'Language:  mean={abilita_linguaggio.mean():.3f}, sd={abilita_linguaggio.std():.3f}')",
    "print(f'Attention: mean={abilita_attenzione.mean():.3f}, sd={abilita_attenzione.std():.3f}')",
]))

# Step 3
md("## Step 3 -- ERP variables")

code('\n'.join([
    "# n400 amplitude [1, 6] uV",
    "z = make_linear_exact({'ling': abilita_linguaggio}, {'ling': 0.8}, rng_n400a, R2_ERP)",
    "n400_amp = np.clip(3.5 + 1.2 * standardize(z), 1, 6)",
    "",
    "# n400 latency [350, 500] ms",
    "z = make_linear_exact(",
    "    {'ling': abilita_linguaggio, 'eta': eta},",
    "    {'ling': -0.7, 'eta': 0.3}, rng_n400l, R2_ERP)",
    "n400_lat = np.clip(425 + 30 * standardize(z), 350, 500)",
    "",
    "# p300 amplitude [5, 20] uV",
    "z = make_linear_exact({'attn': abilita_attenzione}, {'attn': 0.8}, rng_p300a, R2_ERP)",
    "p300_amp = np.clip(12.5 + 3.5 * standardize(z), 5, 20)",
    "",
    "# p300 latency [300, 450] ms",
    "z = make_linear_exact(",
    "    {'attn': abilita_attenzione, 'eta': eta},",
    "    {'attn': -0.7, 'eta': 0.3}, rng_p300l, R2_ERP)",
    "p300_lat = np.clip(375 + 30 * standardize(z), 300, 450)",
    "",
    "print('ERP variables generated.')",
]))

# ERP plot
md("### Quick check -- ERP distributions")

code('\n'.join([
    "fig, axes = plt.subplots(1, 4, figsize=(14, 3))",
    "for ax, vals, name in zip(",
    "    axes, [n400_amp, n400_lat, p300_amp, p300_lat],",
    "    ['n400_amp', 'n400_lat', 'p300_amp', 'p300_lat']):",
    "    ax.hist(vals, bins='auto', edgecolor='white')",
    "    ax.axvline(np.mean(vals), color='C3', ls='--', label=f'mean={np.mean(vals):.1f}')",
    "    ax.set_title(f'{name}\\nn={len(vals)}')",
    "    ax.legend(fontsize=8)",
    "plt.tight_layout()",
    "plt.show()",
]))

# Step 4
md("## Step 4 -- Cognitive tests (from ERP + covariates)")

code('\n'.join([
    "# APACS [0, 1], normalised",
    "z = make_linear_exact(",
    "    {k: eval(k) for k in ['n400_lat', 'n400_amp', 'criq', 'eta', 'sesso']},",
    "    {'n400_lat': -0.30, 'n400_amp': 0.18, 'criq': 0.30, 'eta': -0.35, 'sesso': 0.0},",
    "    rng_apacs, R2_TEST)",
    "apacs = np.clip(0.75 + 0.12 * standardize(z), 0, 1)",
    "",
    "# Matrici Attentive [0, 60]",
    "z = make_linear_exact(",
    "    {k: eval(k) for k in ['p300_lat', 'p300_amp', 'criq', 'eta', 'sesso']},",
    "    {'p300_lat': -0.32, 'p300_amp': 0.30, 'criq': 0.30, 'eta': -0.35, 'sesso': 0.0},",
    "    rng_matr, R2_TEST)",
    "matrici = np.clip(35 + 12 * standardize(z), 0, 60)",
    "",
    "# MoCA [0, 30]",
    "z = make_linear_exact(",
    "    {k: eval(k) for k in ['n400_lat', 'n400_amp', 'p300_lat', 'p300_amp', 'criq', 'eta', 'sesso']},",
    "    {'n400_lat': -0.05, 'n400_amp': 0.05, 'p300_lat': -0.05, 'p300_amp': 0.05,",
    "     'criq': 0.30, 'eta': -0.35, 'sesso': 0.0},",
    "    rng_moca, R2_TEST)",
    "moca = np.clip(22 + 5 * standardize(z), 0, 30)",
    "",
    "print('Cognitive tests generated (from ERP + covariates).')",
]))

# Test plot
md("### Quick check -- test distributions")

code('\n'.join([
    "fig, axes = plt.subplots(1, 3, figsize=(12, 3.5))",
    "for ax, vals, name, mx in zip(",
    "    axes, [apacs, matrici, moca],",
    "    ['APACS', 'Matrici Attentive', 'MoCA'],",
    "    [1, 60, 30]):",
    "    ax.hist(vals, bins='auto', edgecolor='white')",
    "    ax.axvline(np.mean(vals), color='C3', ls='--', label=f'mean={np.mean(vals):.2f}')",
    "    ax.set_title(f'{name} (max={mx})\\nn={len(vals)}')",
    "    ax.legend(fontsize=8)",
    "plt.tight_layout()",
    "plt.show()",
]))

# Validation - correlation matrix
md("## Validation -- correlation matrix")

code('\n'.join([
    "all_vars = pd.DataFrame({",
    "    'gravita': gravita, 'eta': eta, 'sesso': sesso,",
    "    'criq': criq, 'education': education,",
    "    'n400_amp': n400_amp, 'n400_lat': n400_lat,",
    "    'p300_amp': p300_amp, 'p300_lat': p300_lat,",
    "    'apacs': apacs, 'matrici': matrici, 'moca': moca,",
    "})",
    "",
    "fig, ax = plt.subplots(figsize=(12, 10))",
    "corr = all_vars.corr(method='pearson')",
    "mask = np.triu(np.ones_like(corr, dtype=bool), k=1)",
    "sns.heatmap(corr, mask=mask, annot=True, fmt='.3f', cmap='RdBu_r',",
    "            vmin=-1, vmax=1, center=0, square=True, ax=ax,",
    "            cbar_kws={'shrink': 0.8})",
    "ax.set_title('Pearson correlation matrix')",
    "plt.tight_layout()",
    "plt.show()",
]))

# Validation - target coefficients
md("## Validation -- target coefficient checks")

code('\n'.join([
    "import statsmodels.api as sm",
    "",
    "def beta_reg(outcome, predictors):",
    "    'Return standardised beta coefficients.'",
    "    y = zscore(all_vars[outcome])",
    "    X = sm.add_constant(zscore(all_vars[predictors]))",
    "    return sm.OLS(y, X).fit()",
    "",
    "print('=' * 62)",
    "print('Target beta checks')",
    "print('=' * 62)",
    "",
    "m1 = beta_reg('matrici', ['p300_lat', 'p300_amp', 'criq', 'eta', 'sesso'])",
    "print(f'\\nP300_lat -> Matrici  : {m1.params[\"p300_lat\"]:.3f}  (target approx -0.32)')",
    "print(f'P300_amp -> Matrici  : {m1.params[\"p300_amp\"]:.3f}  (target approx +0.30)')",
    "print(f'Matrici R2 = {m1.rsquared:.3f}  (target 0.25-0.40)')",
    "",
    "m2 = beta_reg('apacs', ['n400_lat', 'n400_amp', 'criq', 'eta', 'sesso'])",
    "print(f'\\nN400_lat -> APACS    : {m2.params[\"n400_lat\"]:.3f}  (target approx -0.30)')",
    "print(f'N400_amp -> APACS    : {m2.params[\"n400_amp\"]:.3f}  (target approx +0.18)')",
    "print(f'APACS R2 = {m2.rsquared:.3f}  (target 0.25-0.40)')",
    "",
    "for name, m in [('Matrici', m1), ('APACS', m2)]:",
    "    print(f'\\n{name}: eta={m.params[\"eta\"]:.3f} (target -0.35), '",
    "          f'criq={m.params[\"criq\"]:.3f} (target +0.30), '",
    "          f'sesso={m.params[\"sesso\"]:.3f} (target 0)')",
    "",
    "m3 = beta_reg('moca',",
    "    ['n400_lat', 'n400_amp', 'p300_lat', 'p300_amp', 'criq', 'eta', 'sesso'])",
    "print(f'\\nMoCA model:')",
    "for p in m3.params.index:",
    "    print(f'  {p}: {m3.params[p]:.3f}')",
    "print(f'MoCA R2 = {m3.rsquared:.3f}  (target 0.25-0.40)')",
]))

# Export
md("## Export to CSV")

code('\n'.join([
    "sub_ids = [f'sub-{i+1:03d}' for i in range(n)]",
    "",
    "df_npsy = pd.DataFrame({",
    "    'subject_id': sub_ids,",
    "    'gravita_lesione': gravita.round(3),",
    "    'eta': eta,",
    "    'sesso': sesso.astype(int),",
    "    'criq': criq.round(1),",
    "    'education': education.astype(int),",
    "    'apacs': apacs.round(4),",
    "    'matrici_attentive': matrici.round(2),",
    "    'moca': moca.round(2),",
    "})",
    "",
    "df_eeg = pd.DataFrame({",
    "    'subject_id': sub_ids,",
    "    'n400_ampiezza': n400_amp.round(3),",
    "    'n400_latenza': n400_lat.round(2),",
    "    'p300_ampiezza': p300_amp.round(3),",
    "    'p300_latenza': p300_lat.round(2),",
    "})",
    "",
    "out = Path('../../')",
    "df_npsy.to_csv(out / 'dataset_NPSY.csv', index=False)",
    "df_eeg.to_csv(out / 'dataset_P300.csv', index=False)",
    "",
    "print(f'Written to {out.resolve()}')",
    "print(f'  dataset_NPSY.csv  {df_npsy.shape}')",
    "print(f'  dataset_P300.csv  {df_eeg.shape}')",
]))

md("*Notebook generated for the EEG-NPSI tutorial.*")

nb.cells = cells
nbf.write(nb, "generate_mock_data.ipynb")
print("Notebook written: generate_mock_data.ipynb")
