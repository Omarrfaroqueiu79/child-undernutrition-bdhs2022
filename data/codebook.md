# Dataset Codebook: BDHS 2022 Child Undernutrition Analytical Dataset

**Dataset File:** `BDHS_2022_child_undernutrition_final.sav` / `BDHS_2022_child_undernutrition_final.csv`  
**Sample Size:** N = 4,087 children aged 0–59 months  
**Survey:** 2022 Bangladesh Demographic and Health Survey (BDHS 2022)  
**Clusters (PSUs):** 670 primary sampling units across all 8 administrative divisions  

---

## 1. Study Identifiers and Survey Design Variables

| Variable Name | Type | Description | Values / Categories |
| :--- | :--- | :--- | :--- |
| `woman_row` | Numeric | Original 1-based row index in BDHS women's master file (`BDHS_cleaned_with_nutrition.sav`) | 16 to 30,065 (3,664 unique mothers) |
| `child_idx` | Numeric | Suffix index of the child in mother's birth history | 1 to 4 |
| `CASEID` | String | Unique DHS respondent identification string | Cluster + Household + Line Number |
| `V001` | Numeric | Cluster number (Primary Sampling Unit) | 1 to 675 |
| `V002` | Numeric | Household number | 1 to 78 |
| `V005` | Numeric | Raw DHS individual sampling weight with 6 implied decimal places | 91,325 to 3,891,736 |
| `Weight` | Numeric | Normalized sampling weight (`V005 / 1,000,000`) | Mean = 1.000 (Sum = 4,086.93) |
| `Cluster_ID` | Factor | Unique community cluster factor for multilevel modeling | 670 clusters |
| `Household_ID` | Factor | Household identifier combining `V001` and `V002` | 3,474 households |

---

## 2. Anthropometric Outcome Variables (WHO Child Growth Standards)

| Variable Name | Type | Description | Values / Categories |
| :--- | :--- | :--- | :--- |
| `STUNTED` | Binary | Chronic malnutrition: Height-for-Age Z-score (HAZ) < -2.0 SD | 0 = Not Stunted (76.72% wtd), 1 = Stunted (23.28% wtd) |
| `WASTED` | Binary | Acute malnutrition: Weight-for-Height Z-score (WHZ) < -2.0 SD | 0 = Not Wasted (88.84% wtd), 1 = Wasted (11.16% wtd) |
| `UNDERWT` | Binary | Composite malnutrition: Weight-for-Age Z-score (WAZ) < -2.0 SD | 0 = Not Underweight (77.81% wtd), 1 = Underweight (22.19% wtd) |
| `HW1` | Numeric | Child age in completed months | 0 to 59 |
| `HW70` | Numeric | Height-for-Age Z-score (multiplied by 100 in DHS raw) | Valid range: -600 to +600 |
| `HW71` | Numeric | Weight-for-Height Z-score (multiplied by 100 in DHS raw) | Valid range: -600 to +600 |
| `HW72` | Numeric | Weight-for-Age Z-score (multiplied by 100 in DHS raw) | Valid range: -600 to +600 |

---

## 3. Child-Level Characteristics

| Variable Name | Type | Description | Values / Categories (Reference Category First) |
| :--- | :--- | :--- | :--- |
| `Child_Age` | Factor | Age category in completed months | 0–11 months (Ref), 12–23 months, 24–35 months, 36–47 months, 48–59 months |
| `Child_Sex` | Factor | Biological sex of child (`B4`) | Male (Ref), Female |
| `Birth_Order` | Factor | Birth rank of the child (`BORD`) | First (Ref), Second/third, Fourth or more |

---

## 4. Maternal Characteristics

| Variable Name | Type | Description | Values / Categories (Reference Category First) |
| :--- | :--- | :--- | :--- |
| `Mother_Age` | Factor | Mother's age in 5-year cohorts (`V013`) | 15–19 (Ref), 20–24, 25–29, 30–34, 35–39, 40–49 |
| `Mother_Education`| Factor | Highest level of formal maternal schooling (`V106`) | No education (Ref), Primary, Secondary, Higher |
| `Children_Ever_Born`| Factor | Total cumulative live births (`V201`) | 0–1 (Ref), 2–3, 4+ |
| `Living_Children` | Factor | Total surviving children (`V218`) | 0–1 (Ref), 2–3, 4+ |
| `Currently_Pregnant`| Factor | Maternal pregnancy status at interview (`V213`) | No (Ref), Yes |

---

## 5. Household Socioeconomic & Environmental Characteristics

| Variable Name | Type | Description | Values / Categories (Reference Category First) |
| :--- | :--- | :--- | :--- |
| `Wealth_Index` | Factor | Composite wealth index quintile grouping (`V190`) | Poor (Ref), Middle, Rich |
| `Drinking_Water` | Factor | JMP source of drinking water (`V113`) | Unimproved (Ref), Improved |
| `Toilet_Facility` | Factor | JMP sanitation facility type (`V116`) | Unimproved (Ref), Improved |
| `Electricity` | Factor | Household has electricity access (`V119`) | No (Ref), Yes |
| `Owns_TV` | Factor | Household ownership of television (`V121`) | No (Ref), Yes |
| `Owns_Refrigerator`| Factor | Household ownership of refrigerator (`V122`) | No (Ref), Yes |
| `Owns_Bicycle` | Factor | Household ownership of bicycle (`V123`) | No (Ref), Yes |
| `Floor_Material` | Factor | Dwelling floor construction quality (`V127`) | Unimproved (Ref), Improved |
| `Wall_Material` | Factor | Dwelling wall construction quality (`V128`) | Unimproved (Ref), Improved |
| `Roof_Material` | Factor | Dwelling roof construction quality (`V129`) | Unimproved (Ref), Improved |

---

## 6. Community Contextual Characteristics

| Variable Name | Type | Description | Values / Categories (Reference Category First) |
| :--- | :--- | :--- | :--- |
| `Region` | Factor | Administrative division of Bangladesh (`V024`) | Barisal (Ref), Chittagong, Dhaka, Khulna, Rajshahi, Rangpur, Sylhet, Mymensingh |
| `Residence` | Factor | Type of place of residence (`V025`) | Urban (Ref), Rural |
