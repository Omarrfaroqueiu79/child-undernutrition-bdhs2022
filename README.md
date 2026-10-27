# Multilevel Determinants of Under-Five Child Undernutrition in Bangladesh: A Nationally Representative Cross-Sectional Study from the Bangladesh Demographic and Health Survey 2022

[![R Version](https://img.shields.io/badge/R-%E2%89%A54.3.0-blue.svg)](https://www.r-project.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Data: BDHS 2022](https://img.shields.io/badge/Data-BDHS%202022-green.svg)](https://dhsprogram.com/data/dataset/Bangladesh_Standard-DHS_2022.cfm)
[![Guidelines: STROBE](https://img.shields.io/badge/Reporting-STROBE%20Compliant-orange.svg)](docs/Supplimentary%20File%201_STROBE_Checklist_Cross_Sectional.docx)

---

## 📌 Overview

This repository provides the replication code, clean analytical dataset, and complete supplementary materials for our study investigating the prevalence and multilevel determinants of under-five child undernutrition (stunting, wasting, and underweight) in Bangladesh using the most recent nationally representative **Bangladesh Demographic and Health Survey (BDHS 2022)**.

### Authors
**Suman Biswas<sup>1*</sup>, Mst. Jakia Afrin<sup>1</sup>, Omar Faroque<sup>1</sup>, Md Lotifur Rohman<sup>1</sup>, Md. Mahamudul Islam<sup>1</sup>, Sheli Shikdar<sup>1</sup>**  
<sup>1</sup> *Department of Statistics and Data Science, Islamic University, Kushtia-7003, Bangladesh*  
<sup>*</sup> *Corresponding Author*

---

## 🎯 Key Empirical Findings

1. **National Burden:**
   - **Stunting (Chronic):** Weighted prevalence = **23.28%** (95% CI: 21.98-24.57)
   - **Wasting (Acute):** Weighted prevalence = **11.16%** (95% CI: 10.20-12.13)
   - **Underweight (Composite):** Weighted prevalence = **22.19%** (95% CI: 20.92-23.46)

2. **The Weaning Vulnerability Window:**
   - Incorporating child age resolved a critical gap in earlier models. Stunting odds more than doubled during the complementary feeding transition (12–23 months: **AOR = 2.38**; 95% CI: 1.85–3.06; 24–35 months: **AOR = 2.25**; 95% CI: 1.76–2.89) relative to infants under 12 months. In contrast, child age was not associated with acute wasting.

3. **Maternal Education & Household Socioeconomic Protection:**
   - Maternal higher education was the single strongest protective determinant against both stunting (**AOR = 0.38**; 95% CI: 0.26–0.56) and underweight (**AOR = 0.37**; 95% CI: 0.25–0.53).
   - Household wealth significantly protected against stunting (Rich **AOR = 0.64**) and underweight (Rich **AOR = 0.66**). Refrigerator ownership was independently protective against underweight (**AOR = 0.75**; 95% CI: 0.62-0.92, p = 0.005), and improved toilet facilities significantly protected against stunting (**AOR = 0.82**; 95% CI: 0.67-0.99, p = 0.041), indicating the role of domestic food preservation.

4. **Community Contextual Clustering:**
   - Two-level hierarchical modeling demonstrated significant community clustering across 670 Primary Sampling Units for stunting (**ICC = 1.19%, MOR = 1.21, LRT $\chi^2 = 16.36, p < 0.001$**) and underweight (**ICC = 1.09%, MOR = 1.20, LRT $\chi^2 = 10.07, p < 0.001$**).
   - Conversely, acute wasting was not clustered at the community level (**ICC = 0.00%, LRT $\chi^2 = 0.13, p = 0.718$**), confirming it operates as an episodic shock driven by proximal maternal parity and household conditions.

---

## 📁 Repository Structure

```text
child-undernutrition-bdhs2022/
│
├── README.md                                    <- Project overview, methodology, findings, and replication instructions
├── LICENSE                                      <- MIT Open Source License
├── .gitignore                                   <- Git ignore specifications
│
├── data/
│   ├── BDHS_2022_child_undernutrition_final.csv <- Analytical dataset (CSV format, N = 4,087 children)
│   ├── BDHS_2022_child_undernutrition_final.sav <- Analytical dataset with full SPSS labels and definitions
│   └── codebook.md                              <- Detailed codebook for all 56 variables
│
├── scripts/
│   ├── Revised_Analysis_Script.R               <- Master R replication script (end-to-end models, tables, and figures)
│   ├── Revised_Analysis_Script_With_All_Figures.R <- Full pipeline script with figures & diagnostics
│   └── format_tables_booktabs.py               <- Standalone Python Booktabs XML table post-processor
│
├── results/
│   ├── BDHS2022_Revised_Tables_All.xlsx         <- Master workbook with all descriptive and multilevel tables
│   ├── Table_1_Prevalence.docx                  <- Table 1: Subgroup distributions and weighted prevalences
│   ├── Table_2_Bivariate.docx                   <- Table 2: Bivariate Pearson Chi-square tests of independence
│   ├── Table_3_Multilevel_Model_III.docx        <- Table 3: Multilevel Model III Adjusted Odds Ratios & 95% CIs
│   ├── Table_S1_Stunting_Multilevel.docx        <- Table S1: Sequential Stunting Models (Null to III)
│   ├── Table_S2_Wasting_Multilevel.docx         <- Table S2: Sequential Wasting Models (Null to III)
│   ├── Table_S3_Underweight_Multilevel.docx     <- Table S3: Sequential Underweight Models (Null to III)
│   └── Table_S4_Multicollinearity_VIF.docx      <- Table S4: Multicollinearity Generalized VIF diagnostics
│
├── figures/
│   ├── Figure_1_Trend_Undernutrition_BDHS_LinePlot_n.png <- Longitudinal trend of undernutrition in Bangladesh
│   ├── Figure_2_Sample_Selection_Flowchart.png           <- STROBE sample selection cascade (PNG)
│   ├── Figure_2_Sample_Selection_Flowchart.pdf           <- STROBE sample selection cascade (Vector PDF)
│   └── Figure_3_Prevalence by Region_BDHS_n.png          <- Map/chart of divisional undernutrition disparities
│
├── docs/
│   └── Supplimentary File 1_STROBE_Checklist_Cross_Sectional.docx <- Completed STROBE checklist
│
└── manuscript/
    ├── Manuscript_Marked.docx                   <- Marked revised manuscript with continuous line numbering
```

---

## ⚙️ Replication Instructions

### Prerequisites
All analyses were conducted using **R (version $\ge$ 4.3.0)**. The required R packages can be installed from CRAN:

```r
install.packages(c(
  "haven", "dplyr", "tidyr", "lme4", "broom.mixed",
  "writexl", "openxlsx", "officer", "flextable", "ggplot2"
))
```

### Running the Complete Pipeline
Clone the repository and run the master analysis script:

```bash
git clone https://github.com/Omarrfaroqueiu79/child-undernutrition-bdhs2022.git
cd child-undernutrition-bdhs2022
Rscript scripts/Revised_Analysis_Script.R
```

The script will automatically:
1. Load the clean analytical dataset (`data/BDHS_2022_child_undernutrition_final.sav`).
2. Compute weighted subgroup prevalences, Wald 95% confidence intervals, and unweighted frequencies (**Table 1**).
3. Perform Pearson Chi-square tests of independence with degrees of freedom and exact p-values (**Table 2**).
4. Fit two-level random-intercept logistic regression models across Stunting, Wasting, and Underweight (**Table 3** and **Tables S1–S3**).
5. Compute between-cluster variance ($\sigma_u^2$), Intraclass Correlation Coefficients (ICC), Median Odds Ratios (MOR), and Likelihood Ratio Tests (LRT).
6. Export all results to Word (`.docx`) and master Excel (`.xlsx`) files in `results/`.

---

## 📊 Analytical Methods & Statistical Framework

The analysis was guided by the **UNICEF Conceptual Framework of Malnutrition**, categorizing determinants into:
* **Immediate (Child-level):** Child age in completed months, sex, birth order.
* **Underlying (Maternal & Household-level):** Maternal age, education, cumulative fertility, living children, pregnancy status, household wealth index, drinking water, sanitation facilities, electricity, housing construction materials, and assets (television, refrigerator, bicycle).
* **Basic / Contextual (Community-level):** Administrative division (8 divisions) and type of residence (urban/rural).

### Model Specification
A two-level random-intercept multilevel logistic regression model was estimated:
$$\text{logit}(p_{ij}) = \beta_0 + \mathbf{X}_{ij}\boldsymbol{\beta} + u_j$$
where:
* $p_{ij}$ is the probability that child $i$ in cluster $j$ is undernourished.
* $\mathbf{X}_{ij}$ is the vector of fixed-effect child, maternal, household, and community covariates.
* $u_j \sim \mathcal{N}(0, \sigma_u^2)$ is the random effect representing unobserved contextual variation across the 670 Primary Sampling Units.

---

## ⚖️ Ethics & Data Availability
* **Ethics Approval:** The 2022 BDHS protocol was approved by the Institutional Review Board (IRB) of ICF International and the National Research Ethics Committee (NREC) of the Bangladesh Medical Research Council (BMRC). Informed written consent was obtained from all participants or their legal guardians.
* **Data Access:** Raw BDHS microdata are accessible upon formal registration through [The DHS Program](https://dhsprogram.com/).

---

## 📜 Citation
If you use the dataset, code, or results from this repository, please cite:

> Biswas, S., Afrin, M. J., Faroque, O., Rohman, M. L., Islam, M. M., & Shikdar, S. (2026). *Multilevel Determinants of Under-Five Child Undernutrition in Bangladesh: A Nationally Representative Cross-Sectional Study from the Bangladesh Demographic and Health Survey 2022.* Department of Statistics and Data Science, Islamic University, Kushtia-7003, Bangladesh.

---

## 📄 License
This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.
