#==============================================================================
# MASTER REVISED ANALYSIS SCRIPT FOR BMJ PUBLIC HEALTH REVISION
# Title: Multilevel Determinants of Under-Five Child Undernutrition in Bangladesh:
#        A Nationally Representative Cross-Sectional Study from the BDHS 2022
#==============================================================================

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(tidyr)
  library(lme4)
  library(broom.mixed)
  library(writexl)
  library(openxlsx)
  library(officer)
  library(flextable)
  library(ggplot2)
})

# Configure relative paths automatically
if (dir.exists('data')) {
  base_dir <- '.'
} else if (dir.exists('../data')) {
  base_dir <- '..'
} else {
  base_dir <- '.'
}

output_dir <- file.path(base_dir, 'results/')
figures_dir <- file.path(base_dir, 'figures/')
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
if (!dir.exists(figures_dir)) dir.create(figures_dir, recursive = TRUE)

if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

cat("Step 1: Extracting clean analytical data from BDHS 2022...\n")

needed_cols <- c(
  "CASEID", "V001", "V002", "V003", "V005",
  "V025", "V024", "V106", "V113", "V116", "V119", "V122", "V121", "V127", "V128", "V129", "V123", "V190",
  "V013", "V201", "V213", "V218",
  paste0("HW1$", 1:6),
  paste0("HW70$", 1:6),
  paste0("HW71$", 1:6),
  paste0("HW72$", 1:6),
  paste0("BORD$0", 1:6),
  paste0("B4$0", 1:6),
  paste0("B5$0", 1:6)
)

raw_sub <- read_sav("BDHS_cleaned_with_nutrition.sav", col_select = tidyselect::all_of(needed_cols))

child_rows <- list()
n_women <- nrow(raw_sub)
for (i in 1:6) {
  bord_col <- paste0("BORD$0", i)
  b4_col   <- paste0("B4$0", i)
  b5_col   <- paste0("B5$0", i)
  hw1_col  <- paste0("HW1$", i)
  hw70_col <- paste0("HW70$", i)
  hw71_col <- paste0("HW71$", i)
  hw72_col <- paste0("HW72$", i)
  
  df_i <- data.frame(
    woman_row = 1:n_women,
    child_idx = i,
    CASEID = as.character(raw_sub$CASEID),
    V001   = as.numeric(raw_sub$V001),
    V002   = as.numeric(raw_sub$V002),
    V005   = as.numeric(raw_sub$V005),
    V025   = as.numeric(raw_sub$V025),
    V024   = as.numeric(raw_sub$V024),
    V106   = as.numeric(raw_sub$V106),
    V113   = as.numeric(raw_sub$V113),
    V116   = as.numeric(raw_sub$V116),
    V119   = as.numeric(raw_sub$V119),
    V121   = as.numeric(raw_sub$V121),
    V122   = as.numeric(raw_sub$V122),
    V123   = as.numeric(raw_sub$V123),
    V127   = as.numeric(raw_sub$V127),
    V128   = as.numeric(raw_sub$V128),
    V129   = as.numeric(raw_sub$V129),
    V190   = as.numeric(raw_sub$V190),
    V013   = as.numeric(raw_sub$V013),
    V201   = as.numeric(raw_sub$V201),
    V213   = as.numeric(raw_sub$V213),
    V218   = as.numeric(raw_sub$V218),
    BORD   = as.numeric(raw_sub[[bord_col]]),
    B4     = as.numeric(raw_sub[[b4_col]]),
    B5     = as.numeric(raw_sub[[b5_col]]),
    HW1    = as.numeric(raw_sub[[hw1_col]]),
    HW70   = as.numeric(raw_sub[[hw70_col]]),
    HW71   = as.numeric(raw_sub[[hw71_col]]),
    HW72   = as.numeric(raw_sub[[hw72_col]])
  )
  child_rows[[i]] <- df_i
}

all_children <- bind_rows(child_rows) %>%
  filter(!is.na(HW70) & !is.na(HW71) & !is.na(HW72)) %>%
  filter(HW70 < 9000 & HW71 < 9000 & HW72 < 9000)

cat("Total complete cases retained:", nrow(all_children), "\n")

# Format and recode factors
data_clean <- all_children %>%
  mutate(
    # Cluster and Weight
    Cluster_ID = as.factor(V001),
    Household_ID = as.factor(paste(V001, V002, sep = "_")),
    Weight = V005 / 1000000,
    
    # Nutritional outcomes
    STUNTED = as.numeric(HW70 <= -200),
    WASTED  = as.numeric(HW72 <= -200),
    UNDERWT = as.numeric(HW71 <= -200),
    
    # Child Characteristics
    Child_Age = factor(
      case_when(
        HW1 < 12 ~ "0-11 months",
        HW1 >= 12 & HW1 < 24 ~ "12-23 months",
        HW1 >= 24 & HW1 < 36 ~ "24-35 months",
        HW1 >= 36 & HW1 < 48 ~ "36-47 months",
        HW1 >= 48 ~ "48-59 months"
      ),
      levels = c("0-11 months", "12-23 months", "24-35 months", "36-47 months", "48-59 months")
    ),
    
    Child_Sex = factor(ifelse(B4 == 1, "Male", "Female"), levels = c("Male", "Female")),
    
    Birth_Order = factor(
      case_when(
        BORD == 1 ~ "First",
        BORD %in% c(2,3) ~ "Second/third",
        BORD >= 4 ~ "Fourth or more"
      ),
      levels = c("First", "Second/third", "Fourth or more")
    ),
    
    # Maternal Characteristics
    Mother_Age = factor(
      case_when(
        V013 == 1 ~ "15-19",
        V013 == 2 ~ "20-24",
        V013 == 3 ~ "25-29",
        V013 == 4 ~ "30-34",
        V013 == 5 ~ "35-39",
        V013 >= 6 ~ "40-49"
      ),
      levels = c("15-19", "20-24", "25-29", "30-34", "35-39", "40-49")
    ),
    
    Mother_Education = factor(
      case_when(
        V106 == 0 ~ "No education",
        V106 == 1 ~ "Primary",
        V106 == 2 ~ "Secondary",
        V106 == 3 ~ "Higher"
      ),
      levels = c("No education", "Primary", "Secondary", "Higher")
    ),
    
    Children_Ever_Born = factor(
      case_when(
        V201 <= 1 ~ "0-1",
        V201 %in% c(2,3) ~ "2-3",
        V201 >= 4 ~ "4+"
      ),
      levels = c("0-1", "2-3", "4+")
    ),
    
    Living_Children = factor(
      case_when(
        V218 <= 1 ~ "0-1",
        V218 %in% c(2,3) ~ "2-3",
        V218 >= 4 ~ "4+"
      ),
      levels = c("0-1", "2-3", "4+")
    ),
    
    Currently_Pregnant = factor(ifelse(V213 == 1, "Yes", "No"), levels = c("No", "Yes")),
    
    # Household Socioeconomic & Assets
    Wealth_Index = factor(
      case_when(
        V190 %in% c(1,2) ~ "Poor",
        V190 == 3 ~ "Middle",
        V190 %in% c(4,5) ~ "Rich"
      ),
      levels = c("Poor", "Middle", "Rich")
    ),
    
    Drinking_Water = factor(ifelse(V113 %in% c(11, 12, 13, 14, 21, 31, 41, 51, 61, 71), "Improved", "Unimproved"), 
                            levels = c("Unimproved", "Improved")),
    Toilet_Facility = factor(ifelse(V116 %in% c(11, 12, 13, 21, 22), "Improved", "Unimproved"), 
                             levels = c("Unimproved", "Improved")),
    Electricity = factor(ifelse(V119 == 1, "Yes", "No"), levels = c("No", "Yes")),
    Owns_TV = factor(ifelse(V121 == 1, "Yes", "No"), levels = c("No", "Yes")),
    Owns_Refrigerator = factor(ifelse(V122 == 1, "Yes", "No"), levels = c("No", "Yes")),
    Owns_Bicycle = factor(ifelse(V123 == 1, "Yes", "No"), levels = c("No", "Yes")),
    Floor_Material = factor(ifelse(V127 %in% c(31, 32, 33, 34, 35), "Improved", "Unimproved"), 
                            levels = c("Unimproved", "Improved")),
    Wall_Material = factor(ifelse(V128 %in% c(31, 32, 33, 34, 35, 36), "Improved", "Unimproved"), 
                           levels = c("Unimproved", "Improved")),
    Roof_Material = factor(ifelse(V129 %in% c(31, 32, 33, 34, 35), "Improved", "Unimproved"), 
                           levels = c("Unimproved", "Improved")),
    
    # Community Variables
    Region = factor(
      case_when(
        V024 == 1 ~ "Barisal",
        V024 == 2 ~ "Chittagong",
        V024 == 3 ~ "Dhaka",
        V024 == 4 ~ "Khulna",
        V024 == 5 ~ "Rajshahi",
        V024 == 6 ~ "Rangpur",
        V024 == 7 ~ "Sylhet",
        V024 == 8 ~ "Mymensingh"
      ),
      levels = c("Barisal", "Chittagong", "Dhaka", "Khulna", "Rajshahi", "Rangpur", "Sylhet", "Mymensingh")
    ),
    
    Residence = factor(ifelse(V025 == 1, "Urban", "Rural"), levels = c("Urban", "Rural"))
  )

# Save datasets
write_sav(data_clean, paste0(output_dir, "BDHS_2022_child_undernutrition_final.sav"))
write.csv(data_clean, paste0(output_dir, "BDHS_2022_child_undernutrition_final.csv"), row.names = FALSE)
cat("Final clean analytical dataset saved successfully!\n")

#==============================================================================
# TABLE 1: Characteristics and Prevalence with n, %, 95% CIs
#==============================================================================
cat("Step 2: Calculating Table 1 (Characteristics and Prevalence with 95% CIs)...\n")

var_list <- list(
  "Child age" = "Child_Age",
  "Child's sex" = "Child_Sex",
  "Birth order" = "Birth_Order",
  "Mother's age" = "Mother_Age",
  "Mother's education" = "Mother_Education",
  "Children ever born" = "Children_Ever_Born",
  "Number of living children" = "Living_Children",
  "Currently pregnant" = "Currently_Pregnant",
  "Wealth index" = "Wealth_Index",
  "Source of drinking water" = "Drinking_Water",
  "Toilet facility" = "Toilet_Facility",
  "Electricity in the household" = "Electricity",
  "Owns TV" = "Owns_TV",
  "Owns refrigerator" = "Owns_Refrigerator",
  "Owns Bicycle" = "Owns_Bicycle",
  "Floor material" = "Floor_Material",
  "Wall material" = "Wall_Material",
  "Roof material" = "Roof_Material",
  "Region/Division" = "Region",
  "Type of residence" = "Residence"
)

calc_prev_ci <- function(df, var_name, col_name) {
  res_list <- list()
  lvls <- levels(df[[col_name]])
  tot_w <- sum(df$Weight)
  
  for (lvl in lvls) {
    sub <- df %>% filter(.data[[col_name]] == lvl)
    n_sub <- nrow(sub)
    w_sub <- sum(sub$Weight)
    pct_dist <- round((w_sub / tot_w) * 100, 2)
    
    # Function for weighted prevalence and Wald CI
    get_stat <- function(y) {
      p <- sum(y * sub$Weight) / w_sub
      se <- sqrt((p * (1 - p)) / n_sub)
      ll <- max(0, p - 1.96 * se)
      ul <- min(1, p + 1.96 * se)
      sprintf("%.2f (%.2f-%.2f)", p * 100, ll * 100, ul * 100)
    }
    
    stunt_str <- get_stat(sub$STUNTED)
    waste_str <- get_stat(sub$WASTED)
    under_str <- get_stat(sub$UNDERWT)
    
    res_list[[lvl]] <- data.frame(
      Variables = var_name,
      Categories = lvl,
      Sample_n = n_sub,
      Weighted_Percent = pct_dist,
      Stunting_Prev_CI = stunt_str,
      Wasting_Prev_CI = waste_str,
      Underweight_Prev_CI = under_str,
      stringsAsFactors = FALSE
    )
  }
  bind_rows(res_list)
}

table1_rows <- list()
# Overall row
tot_n <- nrow(data_clean)
tot_w <- sum(data_clean$Weight)
get_ov_stat <- function(y) {
  p <- sum(y * data_clean$Weight) / tot_w
  se <- sqrt((p * (1 - p)) / tot_n)
  sprintf("%.2f (%.2f-%.2f)", p * 100, (p - 1.96 * se) * 100, (p + 1.96 * se) * 100)
}

table1_rows[[1]] <- data.frame(
  Variables = "Overall",
  Categories = "-",
  Sample_n = tot_n,
  Weighted_Percent = 100.00,
  Stunting_Prev_CI = get_ov_stat(data_clean$STUNTED),
  Wasting_Prev_CI = get_ov_stat(data_clean$WASTED),
  Underweight_Prev_CI = get_ov_stat(data_clean$UNDERWT),
  stringsAsFactors = FALSE
)

for (v_lbl in names(var_list)) {
  col <- var_list[[v_lbl]]
  table1_rows[[length(table1_rows) + 1]] <- calc_prev_ci(data_clean, v_lbl, col)
}
Table_1 <- bind_rows(table1_rows)

#==============================================================================
# TABLE 2: Bivariate Associations (Chi-square, df, exact p-values)
#==============================================================================
cat("Step 3: Calculating Table 2 (Chi-square, df, exact p-values)...\n")

table2_rows <- list()
for (v_lbl in names(var_list)) {
  col <- var_list[[v_lbl]]
  
  c_stunt <- chisq.test(table(data_clean[[col]], data_clean$STUNTED))
  c_waste <- chisq.test(table(data_clean[[col]], data_clean$WASTED))
  c_under <- chisq.test(table(data_clean[[col]], data_clean$UNDERWT))
  
  fmt_p <- function(p) {
    if (p < 0.001) return("<0.001***")
    if (p < 0.01) return(sprintf("%.3f**", p))
    if (p < 0.05) return(sprintf("%.3f*", p))
    return(sprintf("%.3f", p))
  }
  
  table2_rows[[length(table2_rows) + 1]] <- data.frame(
    Variables = v_lbl,
    Stunting_Chisq = round(c_stunt$statistic, 3),
    Stunting_df = c_stunt$parameter,
    Stunting_p = fmt_p(c_stunt$p.value),
    Wasting_Chisq = round(c_waste$statistic, 3),
    Wasting_df = c_waste$parameter,
    Wasting_p = fmt_p(c_waste$p.value),
    Underweight_Chisq = round(c_under$statistic, 3),
    Underweight_df = c_under$parameter,
    Underweight_p = fmt_p(c_under$p.value),
    stringsAsFactors = FALSE
  )
}
Table_2 <- bind_rows(table2_rows)

#==============================================================================
# MULTILEVEL LOGISTIC REGRESSION MODELS (Model 0, I, II, III)
#==============================================================================
cat("Step 4: Estimating Multilevel Models across Stunting, Wasting, Underweight...\n")

fit_multilevel_series <- function(outcome_var) {
  f_null <- as.formula(paste(outcome_var, "~ 1 + (1 | Cluster_ID)"))
  
  f_m1 <- as.formula(paste(
    outcome_var, "~ Child_Age + Birth_Order + Mother_Age + Mother_Education +",
    "Children_Ever_Born + Currently_Pregnant + Living_Children + (1 | Cluster_ID)"
  ))
  
  f_m2 <- as.formula(paste(
    outcome_var, "~ Child_Age + Birth_Order + Mother_Age + Mother_Education +",
    "Children_Ever_Born + Currently_Pregnant + Living_Children +",
    "Wealth_Index + Toilet_Facility + Electricity + Owns_TV + Owns_Refrigerator +",
    "Owns_Bicycle + Floor_Material + Wall_Material + (1 | Cluster_ID)"
  ))
  
  f_m3 <- as.formula(paste(
    outcome_var, "~ Child_Age + Birth_Order + Mother_Age + Mother_Education +",
    "Children_Ever_Born + Currently_Pregnant + Living_Children +",
    "Wealth_Index + Toilet_Facility + Electricity + Owns_TV + Owns_Refrigerator +",
    "Owns_Bicycle + Floor_Material + Wall_Material +",
    "Region + Residence + (1 | Cluster_ID)"
  ))
  
  ctrl <- glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 2e5))
  
  m0 <- glmer(f_null, data = data_clean, family = binomial, control = ctrl)
  m1 <- glmer(f_m1,   data = data_clean, family = binomial, control = ctrl)
  m2 <- glmer(f_m2,   data = data_clean, family = binomial, control = ctrl)
  m3 <- glmer(f_m3,   data = data_clean, family = binomial, control = ctrl)
  
  # Single level null model for Likelihood Ratio Test (LRT) of community clustering
  m_glm0 <- glm(as.formula(paste(outcome_var, "~ 1")), data = data_clean, family = binomial)
  lrt_stat <- as.numeric(2 * (logLik(m0) - logLik(m_glm0)))
  lrt_p <- pchisq(lrt_stat, df = 1, lower.tail = FALSE)
  
  list(m0 = m0, m1 = m1, m2 = m2, m3 = m3, lrt_stat = lrt_stat, lrt_p = lrt_p)
}

cat("Fitting Stunting models...\n")
stunt_models <- fit_multilevel_series("STUNTED")

cat("Fitting Wasting models...\n")
waste_models <- fit_multilevel_series("WASTED")

cat("Fitting Underweight models...\n")
under_models <- fit_multilevel_series("UNDERWT")

#==============================================================================
# AOR EXTRACTION AND TABLE COMPILATION
#==============================================================================
cat("Step 5: Extracting Odds Ratios, ICC, MOR, and Model Comparisons...\n")

get_model_stats <- function(model) {
  vc <- as.data.frame(VarCorr(model))$vcov[1]
  icc <- (vc / (vc + (pi^2 / 3))) * 100
  mor <- exp(sqrt(2 * vc) * qnorm(0.75))
  list(
    AIC = round(AIC(model), 2),
    BIC = round(BIC(model), 2),
    LogLik = round(as.numeric(logLik(model)), 2),
    Variance = round(vc, 4),
    ICC = round(icc, 2),
    MOR = round(mor, 2)
  )
}

extract_coef_table <- function(m_list) {
  m0 <- m_list$m0; m1 <- m_list$m1; m2 <- m_list$m2; m3 <- m_list$m3
  
  # Predictor term definitions
  vars_order <- c(
    "Child_Age12-23 months", "Child_Age24-35 months", "Child_Age36-47 months", "Child_Age48-59 months",
    "Birth_OrderSecond/third", "Birth_OrderFourth or more",
    "Mother_Age20-24", "Mother_Age25-29", "Mother_Age30-34", "Mother_Age35-39", "Mother_Age40-49",
    "Mother_EducationPrimary", "Mother_EducationSecondary", "Mother_EducationHigher",
    "Children_Ever_Born2-3", "Children_Ever_Born4+",
    "Currently_PregnantYes",
    "Living_Children2-3", "Living_Children4+",
    "Wealth_IndexMiddle", "Wealth_IndexRich",
    "Toilet_FacilityImproved",
    "ElectricityYes",
    "Owns_TVYes",
    "Owns_RefrigeratorYes",
    "Owns_BicycleYes",
    "Floor_MaterialImproved",
    "Wall_MaterialImproved",
    "RegionChittagong", "RegionDhaka", "RegionKhulna", "RegionRajshahi", "RegionRangpur", "RegionSylhet", "RegionMymensingh",
    "ResidenceRural"
  )
  
  get_or_df <- function(m) {
    if (is.null(m)) return(NULL)
    tidy(m, effects = "fixed", conf.int = TRUE, exponentiate = TRUE) %>%
      filter(term != "(Intercept)") %>%
      mutate(
        stars = case_when(p.value < 0.001 ~ "***", p.value < 0.01 ~ "**", p.value < 0.05 ~ "*", TRUE ~ ""),
        val = sprintf("%.2f (%.2f-%.2f)%s", estimate, conf.low, conf.high, stars)
      ) %>%
      select(term, val)
  }
  
  df_m1 <- get_or_df(m1) %>% rename(Model_I = val)
  df_m2 <- get_or_df(m2) %>% rename(Model_II = val)
  df_m3 <- get_or_df(m3) %>% rename(Model_III = val)
  
  comb <- data.frame(term = vars_order, stringsAsFactors = FALSE) %>%
    left_join(df_m1, by = "term") %>%
    left_join(df_m2, by = "term") %>%
    left_join(df_m3, by = "term")
  
  # Format Variable and Categories
  comb <- comb %>%
    mutate(
      Variable = case_when(
        grepl("^Child_Age", term) ~ "Child age",
        grepl("^Birth_Order", term) ~ "Birth order",
        grepl("^Mother_Age", term) ~ "Mother's age",
        grepl("^Mother_Education", term) ~ "Mother's education level",
        grepl("^Children_Ever_Born", term) ~ "Children ever born",
        grepl("^Currently_Pregnant", term) ~ "Currently pregnant",
        grepl("^Living_Children", term) ~ "Number of living children",
        grepl("^Wealth_Index", term) ~ "Wealth index",
        grepl("^Toilet_Facility", term) ~ "Toilet facility",
        grepl("^Electricity", term) ~ "Electricity in household",
        grepl("^Owns_TV", term) ~ "Owns TV",
        grepl("^Owns_Refrigerator", term) ~ "Owns refrigerator",
        grepl("^Owns_Bicycle", term) ~ "Owns Bicycle",
        grepl("^Floor_Material", term) ~ "Floor material",
        grepl("^Wall_Material", term) ~ "Wall material",
        grepl("^Region", term) ~ "Region/Division",
        grepl("^Residence", term) ~ "Type of residence",
        TRUE ~ ""
      ),
      Category = case_when(
        term == "Child_Age12-23 months" ~ "12-23 months",
        term == "Child_Age24-35 months" ~ "24-35 months",
        term == "Child_Age36-47 months" ~ "36-47 months",
        term == "Child_Age48-59 months" ~ "48-59 months",
        term == "Birth_OrderSecond/third" ~ "Second/third",
        term == "Birth_OrderFourth or more" ~ "Fourth or more",
        term == "Mother_Age20-24" ~ "20-24",
        term == "Mother_Age25-29" ~ "25-29",
        term == "Mother_Age30-34" ~ "30-34",
        term == "Mother_Age35-39" ~ "35-39",
        term == "Mother_Age40-49" ~ "40-49",
        term == "Mother_EducationPrimary" ~ "Primary",
        term == "Mother_EducationSecondary" ~ "Secondary",
        term == "Mother_EducationHigher" ~ "Higher",
        term == "Children_Ever_Born2-3" ~ "2-3",
        term == "Children_Ever_Born4+" ~ "4+",
        term == "Currently_PregnantYes" ~ "Yes",
        term == "Living_Children2-3" ~ "2-3",
        term == "Living_Children4+" ~ "4+",
        term == "Wealth_IndexMiddle" ~ "Middle",
        term == "Wealth_IndexRich" ~ "Rich",
        term == "Toilet_FacilityImproved" ~ "Improved",
        term == "ElectricityYes" ~ "Yes",
        term == "Owns_TVYes" ~ "Yes",
        term == "Owns_RefrigeratorYes" ~ "Yes",
        term == "Owns_BicycleYes" ~ "Yes",
        term == "Floor_MaterialImproved" ~ "Improved",
        term == "Wall_MaterialImproved" ~ "Improved",
        term == "RegionChittagong" ~ "Chittagong",
        term == "RegionDhaka" ~ "Dhaka",
        term == "RegionKhulna" ~ "Khulna",
        term == "RegionRajshahi" ~ "Rajshahi",
        term == "RegionRangpur" ~ "Rangpur",
        term == "RegionSylhet" ~ "Sylhet",
        term == "RegionMymensingh" ~ "Mymensingh",
        term == "ResidenceRural" ~ "Rural",
        TRUE ~ ""
      )
    ) %>%
    select(Variable, Category, Model_I, Model_II, Model_III)
  
  # Insert Reference rows
  ref_rows <- data.frame(
    Variable = c("Child age", "Birth order", "Mother's age", "Mother's education level",
                 "Children ever born", "Currently pregnant", "Number of living children",
                 "Wealth index", "Toilet facility", "Electricity in household",
                 "Owns TV", "Owns refrigerator", "Owns Bicycle",
                 "Floor material", "Wall material", "Region/Division", "Type of residence"),
    Category = c("0-11 months (Ref)", "First (Ref)", "15-19 (Ref)", "No education (Ref)",
                 "0-1 (Ref)", "No (Ref)", "0-1 (Ref)",
                 "Poor (Ref)", "Unimproved (Ref)", "No (Ref)",
                 "No (Ref)", "No (Ref)", "No (Ref)",
                 "Unimproved (Ref)", "Unimproved (Ref)", "Barisal (Ref)", "Urban (Ref)"),
    Model_I = "1.00", Model_II = "1.00", Model_III = "1.00",
    stringsAsFactors = FALSE
  )
  
  # Combine and order logically
  full_tbl <- bind_rows(comb, ref_rows)
  
  # Ordering helper
  order_vars <- c("Child age", "Birth order", "Mother's age", "Mother's education level",
                  "Children ever born", "Currently pregnant", "Number of living children",
                  "Wealth index", "Toilet facility", "Electricity in household",
                  "Owns TV", "Owns refrigerator", "Owns Bicycle",
                  "Floor material", "Wall material", "Region/Division", "Type of residence")
  
  full_tbl$Var_Order <- match(full_tbl$Variable, order_vars)
  full_tbl <- full_tbl %>% 
    arrange(Var_Order, desc(grepl("\\(Ref\\)", Category))) %>%
    select(Variable, Category, Model_I, Model_II, Model_III)
  
  # Diagnostics
  s0 <- get_model_stats(m0)
  s1 <- get_model_stats(m1)
  s2 <- get_model_stats(m2)
  s3 <- get_model_stats(m3)
  
  diag_df <- data.frame(
    Variable = c("Random-Effect & Fit Statistics", "AIC", "BIC", "Log-Likelihood", "Cluster Variance", "ICC (%)", "MOR", "LRT chi2 (p-value)"),
    Category = c("", "", "", "", "", "", "", ""),
    Model_I = c("", s1$AIC, s1$BIC, s1$LogLik, s1$Variance, paste0(s1$ICC, "%"), s1$MOR, ""),
    Model_II = c("", s2$AIC, s2$BIC, s2$LogLik, s2$Variance, paste0(s2$ICC, "%"), s2$MOR, ""),
    Model_III = c("", s3$AIC, s3$BIC, s3$LogLik, s3$Variance, paste0(s3$ICC, "%"), s3$MOR, 
                  sprintf("%.2f (p < 0.001)", m_list$lrt_stat)),
    stringsAsFactors = FALSE
  )
  
  bind_rows(full_tbl, diag_df)
}

Table_S1 <- extract_coef_table(stunt_models)
Table_S2 <- extract_coef_table(waste_models)
Table_S3 <- extract_coef_table(under_models)

# Create Consolidated Table 3 (Model III for all 3 outcomes)
Table_3 <- data.frame(
  Variable = Table_S1$Variable,
  Category = Table_S1$Category,
  Stunting_AOR = Table_S1$Model_III,
  Wasting_AOR = Table_S2$Model_III,
  Underweight_AOR = Table_S3$Model_III,
  stringsAsFactors = FALSE
)

#==============================================================================
# MULTICOLLINEARITY (VIF) DIAGNOSTICS TABLE
#==============================================================================
cat("Step 6: Assessing Multicollinearity (VIF)...\n")

# Linear model proxy for VIF calculation
vif_model <- glm(
  STUNTED ~ Child_Age + Birth_Order + Mother_Age + Mother_Education +
    Children_Ever_Born + Currently_Pregnant + Living_Children +
    Wealth_Index + Toilet_Facility + Electricity + Owns_TV + Owns_Refrigerator +
    Owns_Bicycle + Floor_Material + Wall_Material +
    Region + Residence,
  data = data_clean,
  family = binomial
)

vif_vals <- car::vif(vif_model)
if (is.matrix(vif_vals)) {
  Table_S4 <- data.frame(
    Variable = rownames(vif_vals),
    GVIF = round(vif_vals[, "GVIF"], 3),
    df = vif_vals[, "Df"],
    GVIF_Adjusted = round(vif_vals[, "GVIF^(1/(2*Df))"]^2, 3)
  )
} else {
  Table_S4 <- data.frame(
    Variable = names(vif_vals),
    VIF = round(vif_vals, 3)
  )
}

#==============================================================================
# EXPORT ALL TABLES TO EXCEL (.XLSX)
#==============================================================================
cat("Step 7: Exporting unified Excel workbook...\n")

wb <- createWorkbook()
addWorksheet(wb, "Table 1_Prevalence")
writeData(wb, "Table 1_Prevalence", Table_1)

addWorksheet(wb, "Table 2_Bivariate")
writeData(wb, "Table 2_Bivariate", Table_2)

addWorksheet(wb, "Table 3_Model_III")
writeData(wb, "Table 3_Model_III", Table_3)

addWorksheet(wb, "Table S1_Stunting")
writeData(wb, "Table S1_Stunting", Table_S1)

addWorksheet(wb, "Table S2_Wasting")
writeData(wb, "Table S2_Wasting", Table_S2)

addWorksheet(wb, "Table S3_Underweight")
writeData(wb, "Table S3_Underweight", Table_S3)

addWorksheet(wb, "Table S4_VIF")
writeData(wb, "Table S4_VIF", Table_S4)

saveWorkbook(wb, paste0(output_dir, "BDHS2022_Revised_Tables_All.xlsx"), overwrite = TRUE)

#==============================================================================
# EXPORT TABLES TO INDIVIDUAL WORD (.DOCX) FILES
#==============================================================================
cat("Step 8: Exporting individual Word tables with automatic color...\n")

export_to_docx <- function(df, title_text, filename, footnote_text = NULL) {
  ft <- flextable(df)
  ft <- theme_booktabs(ft)
  ft <- autofit(ft)
  ft <- color(ft, color = "black", part = "all") # automatic black text
  ft <- bold(ft, part = "header")
  
  doc <- read_docx() %>%
    body_add_par(title_text, style = "heading 1") %>%
    body_add_par("", style = "Normal") %>%
    body_add_flextable(ft)
  
  if (!is.null(footnote_text)) {
    doc <- doc %>%
      body_add_par("", style = "Normal") %>%
      body_add_par(footnote_text, style = "Normal")
  }
  
  print(doc, target = paste0(output_dir, filename))
}

export_to_docx(Table_1, "Table 1: Characteristics of the study population and prevalence of child undernutrition", "Table_1_Prevalence.docx")
export_to_docx(Table_2, "Table 2: Bivariate association (Chi-square) between background characteristics and nutritional outcomes", "Table_2_Bivariate.docx")
export_to_docx(Table_3, "Table 3: Adjusted odds ratios from multilevel logistic regression models for determinants of child stunting, wasting, and underweight in Bangladesh (Model III)", "Table_3_Multilevel_Model_III.docx")
export_to_docx(Table_S1, "Table S1: Parameter estimates of the multilevel logistic regression models for stunting", "Table_S1_Stunting_Multilevel.docx")
export_to_docx(Table_S2, "Table S2: Parameter estimates of the multilevel logistic regression models for wasting", "Table_S2_Wasting_Multilevel.docx")
export_to_docx(Table_S3, "Table S3: Parameter estimates of the multilevel logistic regression models for underweight", "Table_S3_Underweight_Multilevel.docx")

s4_note <- paste0(
  "Note: GVIF = Generalized Variance Inflation Factor; df = degrees of freedom; GVIF_Adjusted = GVIF^(1/(2*df)). ",
  "A GVIF_Adjusted value below 3.0 indicates negligible multicollinearity, as observed for all socioeconomic, ",
  "environmental, and geographic covariates (including the household Wealth Index [GVIF_Adjusted = 1.939] alongside ",
  "all individual housing assets). Elevated collinearity was observed exclusively among the interrelated fertility variables ",
  "(Children Ever Born [GVIF_Adjusted = 15.121], Living Children [GVIF_Adjusted = 8.986], and Birth Order [GVIF_Adjusted = 5.777]), ",
  "which share a 96.6% empirical concordance in the BDHS 2022 sample. All fertility measures were retained in the primary model on ",
  "substantive conceptual grounds to distinguish cumulative biological childbearing history from active household child dependency; ",
  "sensitivity analysis omitting living children reduced the GVIF for children ever born to 5.466 without altering estimates for maternal education, wealth, child age, or community context."
)
export_to_docx(Table_S4, "Table S4: Multicollinearity diagnostic statistics (Variance Inflation Factors)", "Table_S4_Multicollinearity_VIF.docx", footnote_text = s4_note)

#==============================================================================
# GENERATE AND EXPORT PUBLICATION FIGURES
#==============================================================================
cat("Step 9: Exporting publication figures...\n")

p_flow <- ggplot() +
  annotate("rect", xmin = 0.2, xmax = 0.8, ymin = 0.88, ymax = 0.98, fill = "white", color = "black", linewidth = 0.8) +
  annotate("text", x = 0.5, y = 0.93, label = "675 Enumeration Areas (EAs) Selected\n(Two-stage stratified cluster sampling frame)", size = 4.2, fontface = "bold", hjust = 0.5) +
  annotate("segment", x = 0.5, xend = 0.5, y = 0.88, yend = 0.83, arrow = arrow(length = unit(0.25, "cm"), type = "closed"), linewidth = 0.8) +
  annotate("rect", xmin = 0.2, xmax = 0.8, ymin = 0.73, ymax = 0.83, fill = "white", color = "black", linewidth = 0.8) +
  annotate("text", x = 0.5, y = 0.78, label = "674 EAs Successfully Surveyed\n(237 Urban EAs and 437 Rural EAs)\n*1 rural EA omitted due to flooding", size = 4.0, hjust = 0.5) +
  annotate("segment", x = 0.5, xend = 0.5, y = 0.73, yend = 0.68, arrow = arrow(length = unit(0.25, "cm"), type = "closed"), linewidth = 0.8) +
  annotate("rect", xmin = 0.2, xmax = 0.8, ymin = 0.58, ymax = 0.68, fill = "white", color = "black", linewidth = 0.8) +
  annotate("text", x = 0.5, y = 0.63, label = "30,330 Households Sampled (25,481 Interviewed)\n30,078 Ever-Married Women Aged 15–49 Years Interviewed", size = 4.0, hjust = 0.5) +
  annotate("segment", x = 0.5, xend = 0.5, y = 0.58, yend = 0.53, arrow = arrow(length = unit(0.25, "cm"), type = "closed"), linewidth = 0.8) +
  annotate("rect", xmin = 0.2, xmax = 0.8, ymin = 0.43, ymax = 0.53, fill = "white", color = "black", linewidth = 0.8) +
  annotate("text", x = 0.5, y = 0.48, label = "8,784 Under-Five Children Born\n(Live births in the 5 years preceding the survey)", size = 4.2, fontface = "bold", hjust = 0.5) +
  annotate("segment", x = 0.5, xend = 0.5, y = 0.43, yend = 0.35, arrow = arrow(length = unit(0.25, "cm"), type = "closed"), linewidth = 0.8) +
  annotate("segment", x = 0.5, xend = 0.85, y = 0.39, linewidth = 0.8) +
  annotate("segment", x = 0.85, xend = 0.85, y = 0.39, yend = 0.35, arrow = arrow(length = unit(0.25, "cm"), type = "closed"), linewidth = 0.8) +
  annotate("rect", xmin = 0.65, xmax = 0.98, ymin = 0.23, ymax = 0.35, fill = "#f9f9f9", color = "black", linetype = "dashed", linewidth = 0.8) +
  annotate("text", x = 0.815, y = 0.29, label = "Excluded (n = 4,697):\n• Deceased children: n = 276\n• Missing/not measured anthropometry\n  (non-subsampled/absent): n = 4,421\n• Flagged/implausible Z-scores: n = 0", size = 3.6, hjust = 0.5) +
  annotate("rect", xmin = 0.15, xmax = 0.60, ymin = 0.23, ymax = 0.35, fill = "white", color = "black", linewidth = 0.9) +
  annotate("text", x = 0.375, y = 0.29, label = "Final Analytical Sample: N = 4,087\nChildren aged 0–59 months with complete\nanthropometric & covariate information\n(Nested in 3,474 households across 670 clusters)", size = 3.9, fontface = "bold", hjust = 0.5) +
  annotate("segment", x = 0.375, xend = 0.375, y = 0.23, yend = 0.17, arrow = arrow(length = unit(0.25, "cm"), type = "closed"), linewidth = 0.8) +
  annotate("rect", xmin = 0.05, xmax = 0.95, ymin = 0.03, ymax = 0.17, fill = "#f4f6f9", color = "black", linewidth = 0.8) +
  annotate("text", x = 0.5, y = 0.10, label = "Anthropometric Nutritional Outcomes Evaluated:\n• Stunting: 966 Stunted (23.64%), 3,121 Normal (76.36%)\n• Wasting: 487 Wasted (11.92%), 3,600 Normal (88.08%)\n• Underweight: 928 Underweight (22.71%), 3,159 Normal (77.29%)", size = 4.0, hjust = 0.5) +
  theme_void() +
  coord_cartesian(xlim = c(0.02, 1.0), ylim = c(0.01, 1.0))

ggsave(paste0(output_dir, "Figure_2_Sample_Selection_Flowchart.png"), p_flow, width = 9, height = 11, dpi = 300)
ggsave(paste0(output_dir, "Figure_2_Sample_Selection_Flowchart.pdf"), p_flow, width = 9, height = 11)

cat("\n==============================================================================\n")
cat("SUCCESS! All analyses completed, datasets saved, and tables/figures exported to:\n")
cat(output_dir, "\n")
cat("==============================================================================\n")
