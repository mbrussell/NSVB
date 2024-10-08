## -----------------------------------------------------------------------------------------------------------------------------------------
# Install packages
library(tidyverse)


## -----------------------------------------------------------------------------------------------------------------------------------------
# Set working directory
setwd("C:/Users/matt/Documents/Arbor/Projects/NSVB/westfall gtr/WO-GTR-104-Supp1")


## -----------------------------------------------------------------------------------------------------------------------------------------
# Species reference table
ref_spp <- read_csv("REF_SPECIES.csv") |> 
  select(SPCD, JENKINS_SPGRPCD) |> 
  filter(SPCD <= 999)


## -----------------------------------------------------------------------------------------------------------------------------------------
# The primary NSVB equations (Eqns 1-5 in Westfall et al. 2023)

get_nsvb <- function(MODEL, SPCD, DIA, HT,
                               a, a1, b, b1, c, c1, WDSG){
  # Schumacher-Hall model
  if (MODEL == 1){
    nsvb = a*DIA**b*HT**c

  # Segmented model
    }else if(MODEL == 2 & SPCD < 300 & DIA < 9){
      nsvb = a*DIA**b1*HT**c
   }else if(MODEL == 2 & SPCD < 300 & DIA >= 9){
     nsvb = a*9**(b-b1)*DIA**b1*HT**c
   }else if(MODEL == 2 & SPCD >= 300 & DIA < 11){
     nsvb = a*DIA**b1*HT**c
   }else if(MODEL == 2 & SPCD >= 300 & DIA >= 11){
     nsvb = a*11**(b-b1)*DIA**b1*HT**c
     
  # Continuously variable model
   }else if(MODEL == 3){
     nsvb = a*DIA**(a1*(1-exp(-1*b*DIA)))**c1*HT**c
     
  # Modified Wiley model
   }else if (MODEL == 4){
    nsvb = a*DIA**b*HT**c*exp(-1*(b1*DIA))
    
  # Modified Schumacher-Hall model
   }else if (MODEL == 5){
    nsvb = a*DIA**b*HT**c*WDSG
    
   }else {
     nsvb = NA
   }
  return(nsvb)
}

# Equation to estimate merchantable height to any top diameter 
# (Eqn 7 in Westfall et al. 2023)

get_hm <- function(top_dia, a, DIA, b, HT, c, alpha, beta) {
  # Define the equation
  equation <- function(hm) {
    result <- top_dia - (a * (DIA^b) * (HT^c) / 0.005454154/ HT * 
                           alpha * beta * (1 - hm/HT)^(alpha-1) *
                           (1 - (1 - hm/HT)^alpha)^(beta-1))**0.5
    return(result)
  }
  
  # Find the value of hm that minimizes the equation
  result <- uniroot(equation, interval = c(1, HT))
  hm_minimized <- result$root
  
  return(hm_minimized)
}

# Equation to get volume ratio (eqn 6 in Westfall et al. 2023)
get_V_ratio <- function(h1, HT, alpha, beta){
    ratio = (1 - (1 - h1/HT)**alpha)**beta
  return(ratio)
}


## -----------------------------------------------------------------------------------------------------------------------------------------
# 1. Gross total stem wood volume, inside bark:

vol_ib <- read_csv("Table S1a_volib_coefs_spcd.csv") |> 
  rename(MODEL = model)
vol_ib_jenkins <- read_csv("Table S1b_volib_coefs_jenkins.csv") |> 
  rename(MODEL = model)

vol_division <- vol_ib |> 
  distinct(DIVISION, SPCD, STDORGCD) |> 
  filter(!is.na(DIVISION))

vol_division_na <- vol_ib |> 
  distinct(DIVISION) |> 
  filter(!is.na(DIVISION))

spp_vol_division <- vol_ib |> 
  filter(!is.na(DIVISION)) |> 
  relocate(DIVISION) |> 
  mutate(coef_level = "SPCD/DIVISION")

vol_ib_division_na <- vol_ib |> 
  filter(is.na(DIVISION)) |> 
  select(-DIVISION)|> 
  mutate(coef_level = "SPCD")

spp_vol_division_na <- cross_join(vol_division_na, vol_ib_division_na)|> 
  arrange(SPCD)|> 
  mutate(coef_level = "SPCD")

spp_vol_ib <- rbind(spp_vol_division, spp_vol_division_na) |> 
  group_by(DIVISION, SPCD) |> 
  slice_max(coef_level) |> 
  arrange(SPCD, desc(DIVISION), STDORGCD) 

vol_ib_jenkins_spp <- inner_join(vol_ib_jenkins, ref_spp, 
                                 by  = join_by(JENKINS_SPGRPCD)) |> 
  arrange(SPCD) |> 
  mutate(coef_level = "SPGRPCD")

spp_already_have <- spp_vol_ib |> 
  group_by(SPCD) |> 
  distinct(SPCD) |> 
  mutate(SPCD_have = 1)

spp_vol_ib_jenkins <- full_join(vol_ib_jenkins_spp, spp_already_have,
                                 by = join_by(SPCD)) |> 
  filter(is.na(SPCD_have)) |> 
  cross_join(vol_division_na) |> 
  add_column(a1 = NA,
             b1 = NA,
             c1 = NA,
             STDORGCD = NA) |> 
  select(-c(SPCD_have, JENKINS_SPGRPCD)) |> 
  relocate(DIVISION, SPCD, STDORGCD, MODEL, a, a1, b, b1, c, c1, coef_level)

spp_vol_ib_all <- rbind(spp_vol_ib, spp_vol_ib_jenkins) |> 
  arrange(SPCD, DIVISION)

tree <- inner_join(tree, spp_vol_ib_all) |> 
  rowwise() |> 
  mutate(V_tot_ib_Gross = get_nsvb(MODEL = MODEL, SPCD = SPCD, 
                                   DIA = DIA, HT = HT,
                                   a = a, a1 = a1, b = b, 
                                   b1 = b1, c = c, c1 = c1,
                                   WDSG = NA))|> 
 select(-c(a, a1, b, b1, c, c1, coef_level, MODEL)) 


## -----------------------------------------------------------------------------------------------------------------------------------------
# 2. Gross total stem bark volume

vol_bark <- read_csv("Table S2a_volbk_coefs_spcd.csv") |> 
  rename(MODEL = model)
vol_bark_jenkins <- read_csv("Table S2b_volbk_coefs_jenkins.csv") |> 
  rename(MODEL = model)

vol_division <- vol_bark |> 
  distinct(DIVISION, SPCD, STDORGCD) |> 
  filter(!is.na(DIVISION))

vol_division_na <- vol_bark |> 
  distinct(DIVISION) |> 
  filter(!is.na(DIVISION))

spp_vol_division <- vol_bark |> 
  filter(!is.na(DIVISION)) |> 
  relocate(DIVISION) |> 
  mutate(coef_level = "SPCD/DIVISION")

vol_bark_division_na <- vol_bark |> 
  filter(is.na(DIVISION)) |> 
  select(-DIVISION)|> 
  mutate(coef_level = "SPCD")

spp_vol_division_na <- cross_join(vol_division_na, vol_bark_division_na)|> 
  arrange(SPCD)|> 
  mutate(coef_level = "SPCD")

spp_vol_bark <- rbind(spp_vol_division, spp_vol_division_na) |> 
  group_by(DIVISION, SPCD) |> 
  slice_max(coef_level) |> 
  arrange(SPCD, desc(DIVISION), STDORGCD) 

vol_bark_jenkins_spp <- inner_join(vol_bark_jenkins, ref_spp, 
                                 by  = join_by(JENKINS_SPGRPCD)) |> 
  arrange(SPCD) |> 
  mutate(coef_level = "SPGRPCD")

spp_already_have <- spp_vol_bark |> 
  group_by(SPCD) |> 
  distinct(SPCD) |> 
  mutate(SPCD_have = 1)

spp_vol_bark_jenkins <- full_join(vol_bark_jenkins_spp, spp_already_have,
                                by = join_by(SPCD)) |> 
  filter(is.na(SPCD_have)) |> 
  cross_join(vol_division_na) |> 
  add_column(a1 = NA,
             b1 = NA,
             c1 = NA,
             STDORGCD = NA) |> 
  select(-c(SPCD_have, JENKINS_SPGRPCD)) |> 
  relocate(DIVISION, SPCD, STDORGCD, MODEL, a, a1, b, b1, c, c1, coef_level)

spp_vol_bark_all <- rbind(spp_vol_bark, spp_vol_bark_jenkins) |> 
  arrange(SPCD, DIVISION)


tree <- inner_join(tree, spp_vol_bark_all) |> 
  rowwise() |> 
  mutate(V_tot_bk_Gross = get_nsvb(MODEL = MODEL, SPCD = SPCD, 
                                     DIA = DIA, HT = HT,
                                     a = a, a1 = a1, b = b, 
                                     b1 = b1, c = c, c1 = c1, 
                                     WDSG = NA),
          # 3. Gross total stem outside-bark volume
          V_tot_ob_Gross = V_tot_ib_Gross + V_tot_bk_Gross) |> 
  select(-c(a, a1, b, b1, c, c1, coef_level, MODEL)) 


## -----------------------------------------------------------------------------------------------------------------------------------------
# tree_trim <- tree |>
#   rename(VOLTSGRS = V_tot_ib_Gross,
#          VOLTSGRS_BARK = V_tot_bk_Gross) |> 
#   select(PROVINCE, DIVISION, ECOSUBCD, STATECD, COUNTYCD, PLOT, SUBP, 
#          TREE, INVYR, SPCD, DIA, HT, 
#          ACTUALHT, CR, CULL, DECAYCD, STATUSCD, 
#          VOLTSGRS,
#          VOLTSGRS_FIA,
#          VOLTSGRS_BARK,
#          VOLTSGRS_BARK_FIA,
#          a, a1, b, b1, c, c1, coef_level, MODEL) |>  
#       mutate(VOLTSGRS_DIFF = VOLTSGRS_FIA - VOLTSGRS,
#              VOLTSGRS_BARK_DIFF = VOLTSGRS_BARK_FIA - VOLTSGRS_BARK) |> 
#   filter(SPCD == 802)
# tree_trim

# p_vol <- ggplot(tree_trim, aes(x = VOLTSGRS_BARK_FIA, y = VOLTSGRS_BARK)) +
#   geom_point()+
#    facet_wrap(~DIVISION) +
# # scale_y_continuous(limits = c(0,30)) +
#  # scale_x_continuous(limits = c(0,30)) +
#   geom_abline(slope = 1, intercept = 0, col = "red")
# p_vol


## -----------------------------------------------------------------------------------------------------------------------------------------
# 4. Estimate height to merchantable top diameter (4.0-inch)

vol_ob1 <- read_csv("Table S3a_volob_coefs_spcd.csv") |> 
  rename(MODEL_ob = model)
vol_ob2 <- read_csv("Table S4a_rcumob_coefs_spcd.csv") |> 
  rename(MODEL_rcumob = model)
vol_ob <- inner_join(vol_ob1, vol_ob2, by = c("SPCD", "DIVISION", "STDORGCD"))

vol_ob1_jenkins <- read_csv("Table S3b_volob_coefs_jenkins.csv") |> 
  rename(MODEL_ob = model)
vol_ob2_jenkins <- read_csv("Table S4b_rcumob_coefs_jenkins.csv") |> 
  rename(MODEL_rcumob = model)
vol_ob_jenkins <- inner_join(vol_ob1_jenkins, vol_ob2_jenkins, 
                             by = c("JENKINS_SPGRPCD"))

vol_division <- vol_ob |> 
  distinct(DIVISION, SPCD, STDORGCD) |> 
  filter(!is.na(DIVISION))

vol_division_na <- vol_ob |> 
  distinct(DIVISION) |> 
  filter(!is.na(DIVISION))

spp_vol_division <- vol_ob |> 
  filter(!is.na(DIVISION)) |> 
  relocate(DIVISION) |> 
  mutate(coef_level = "SPCD/DIVISION")

vol_ob_division_na <- vol_ob |> 
  filter(is.na(DIVISION)) |> 
  select(-DIVISION)|> 
  mutate(coef_level = "SPCD")

spp_vol_division_na <- cross_join(vol_division_na, vol_ob_division_na)|> 
  arrange(SPCD)|> 
  mutate(coef_level = "SPCD")

spp_vol_ob <- rbind(spp_vol_division, spp_vol_division_na) |> 
  group_by(DIVISION, SPCD) |> 
  slice_max(coef_level) |> 
  arrange(SPCD, desc(DIVISION), STDORGCD) 


vol_ob_jenkins_spp <- inner_join(vol_ob_jenkins, ref_spp, 
                                 by  = join_by(JENKINS_SPGRPCD)) |> 
  arrange(SPCD) |> 
  mutate(coef_level = "SPGRPCD")

spp_already_have <- spp_vol_ob |> 
  group_by(SPCD) |> 
  distinct(SPCD) |> 
  mutate(SPCD_have = 1)

spp_vol_ob_jenkins <- full_join(vol_ob_jenkins_spp, spp_already_have,
                                 by = join_by(SPCD)) |> 
  filter(is.na(SPCD_have)) |> 
  cross_join(vol_division_na) |> 
  add_column(STDORGCD = NA) |> 
  select(-c(SPCD_have, JENKINS_SPGRPCD)) |> 
  relocate(DIVISION, SPCD, STDORGCD, MODEL_ob, a, b, c, MODEL_rcumob, 
           alpha, beta, coef_level)

spp_vol_ob_all <- rbind(spp_vol_ob, spp_vol_ob_jenkins) |> 
  arrange(SPCD, DIVISION)

tree <- inner_join(tree, spp_vol_ob_all) |> 
  rowwise() |> 
  mutate(hm = ifelse(DIA >= 5, get_hm(top_dia = 4, a = a, b = b, c = c,
                       alpha = alpha, beta = beta,
                       DIA = DIA, HT = HT), NA)) |> 
  select(-c(a, b, c, alpha, beta, MODEL_ob, MODEL_rcumob, coef_level))


## -----------------------------------------------------------------------------------------------------------------------------------------
# 5. Estimate merchantable wood volume – volume ratios to stump & merchantable top

vol_ratio <- read_csv("Table S5a_rcumib_coefs_spcd.csv") |> 
  rename(MODEL = model)
vol_ratio_jenkins <- read_csv("Table S5b_rcumib_coefs_jenkins.csv") |> 
  rename(MODEL = model)

vol_division <- vol_ratio |> 
  distinct(DIVISION, SPCD, STDORGCD) |> 
  filter(!is.na(DIVISION))

vol_division_na <- vol_ratio |> 
  distinct(DIVISION) |> 
  filter(!is.na(DIVISION))

spp_vol_division <- vol_ratio |> 
  filter(!is.na(DIVISION)) |> 
  relocate(DIVISION) |> 
  mutate(coef_level = "SPCD/DIVISION")

vol_ratio_division_na <- vol_ratio |> 
  filter(is.na(DIVISION)) |> 
  select(-DIVISION)|> 
  mutate(coef_level = "SPCD")

spp_vol_division_na <- cross_join(vol_division_na, vol_ratio_division_na)|> 
  arrange(SPCD)|> 
  mutate(coef_level = "SPCD")

spp_vol_ratio <- rbind(spp_vol_division, spp_vol_division_na) |> 
  group_by(DIVISION, SPCD) |> 
  slice_max(coef_level) |> 
  arrange(SPCD, desc(DIVISION), STDORGCD) 

vol_ratio_jenkins_spp <- inner_join(vol_ratio_jenkins, ref_spp, 
                                 by  = join_by(JENKINS_SPGRPCD)) |> 
  arrange(SPCD) |> 
  mutate(coef_level = "SPGRPCD")

spp_already_have <- spp_vol_ratio |> 
  group_by(SPCD) |> 
  distinct(SPCD) |> 
  mutate(SPCD_have = 1)

spp_vol_ratio_jenkins <- full_join(vol_ratio_jenkins_spp, spp_already_have,
                                 by = join_by(SPCD)) |> 
  filter(is.na(SPCD_have)) |> 
  cross_join(vol_division_na) |> 
  add_column(STDORGCD = NA) |> 
  select(-c(SPCD_have, JENKINS_SPGRPCD)) |> 
  relocate(DIVISION, SPCD, STDORGCD, MODEL, alpha, beta, coef_level)

spp_vol_ratio_all <- rbind(spp_vol_ratio, spp_vol_ratio_jenkins) |> 
  arrange(SPCD, DIVISION)

tree <- inner_join(tree, spp_vol_ratio_all) |> 
  rowwise() |> 
  mutate(R_1 = get_V_ratio(h1 = 1, HT = HT, alpha = alpha, beta = beta),
         # R_1 = ifelse(DIA >= 5, get_V_ratio(h1 = 1, HT = HT,
         #                            alpha = alpha, beta = beta), NA),
         R_m = ifelse(DIA >= 5, get_V_ratio(h1 = hm, HT = HT, 
                                    alpha = alpha, beta = beta), NA),
         R_m_2 = get_V_ratio(h1 = ACTUALHT, HT = HT, 
                                    alpha = alpha, beta = beta),
         V_mer_ib_Gross = (R_m * V_tot_ib_Gross ) - (R_1 * V_tot_ib_Gross),
         V_mer_ob_Gross = (R_m * V_tot_ob_Gross ) - (R_1 * V_tot_ob_Gross),
         V_mer_bk_Gross = V_mer_ob_Gross - V_mer_ib_Gross) |> 
  select(-c(alpha, beta, MODEL, coef_level))


## -----------------------------------------------------------------------------------------------------------------------------------------
# Volume in the sawlog portion of the stem
tree <- inner_join(tree, spp_vol_ob_all) |> 
  rowwise() |> 
  mutate(hm_saw = ifelse(SPCD < 300 & DIA >= 9.0, 
                         get_hm(top_dia = 7, a = a, b = b, c = c,
                                  alpha = alpha, beta = beta,
                                  DIA = DIA, HT = HT),
                     ifelse(SPCD >= 300 & DIA >= 11.0,
                            get_hm(top_dia = 9, a = a, b = b, c = c,
                                     alpha = alpha, beta = beta,
                                     DIA = DIA, HT = HT), NA))) |> 
  select(-c(a, b, c, alpha, beta, MODEL_ob, MODEL_rcumob, coef_level))


## -----------------------------------------------------------------------------------------------------------------------------------------
# Sawlog volumes ratios - stump and merchantable height

tree <- inner_join(tree, spp_vol_ratio_all) |> 
  rowwise() |> 
  mutate(R_s = get_V_ratio(h1 = hm_saw, HT = HT, 
                                    alpha = alpha, beta = beta)) |> 
  select(-c(alpha, beta, MODEL, coef_level))


## -----------------------------------------------------------------------------------------------------------------------------------------
# More tree-level calcs here

tree <- tree |> 
  mutate(CULL = ifelse(is.na(CULL), 0, CULL),
         V_saw_ib_Gross = (R_s * V_tot_ib_Gross) - (R_1 * V_tot_ib_Gross),
         V_saw_ob_Gross = (R_s * V_tot_ob_Gross) - (R_1 * V_tot_ob_Gross),
         V_saw_bk_Gross = V_saw_ob_Gross - V_saw_ib_Gross,
         V_stump_ob_Gross = (R_1 * V_tot_ob_Gross), 
         V_stump_ib_Gross = (R_1 * V_tot_ib_Gross),
         V_stump_bk_Gross = V_stump_ob_Gross - V_stump_ib_Gross,
         V_top_ob_Gross = V_tot_ob_Gross - V_mer_ob_Gross - V_stump_ob_Gross,
         V_top_ib_Gross = V_tot_ib_Gross - V_mer_ib_Gross - V_stump_ib_Gross,
         V_top_bk_Gross = V_top_ob_Gross - V_top_ib_Gross,
         V_top_bk_Sound = 0,
    
         # broken tops
          
         V_mer_ib_Sound = ((R_m_2 * V_tot_ib_Gross) - (R_1 * V_tot_ib_Gross)) * 
           (1 - CULL/100),
         V_mer_ib_Sound2 = ((R_m_2 * V_tot_ib_Gross) - (R_1 * V_tot_ib_Gross)) * 
           (1 - 0/100),
         V_mer_bk_Sound = ((R_m_2 * V_tot_bk_Gross) - (R_1 * V_tot_bk_Gross)), 
         V_mer_ob_Sound = V_mer_ib_Sound + V_mer_bk_Sound,
         V_mer_ob_Sound2 = V_mer_ib_Sound2 + V_mer_bk_Sound,
         V_stump_ib_Sound = V_stump_ib_Gross * (1 - CULL/100),
         V_stump_ob_Sound = V_stump_ib_Sound + V_stump_bk_Gross,
         
         # Live trees
         V_tot_ib_Sound = ifelse(STATUSCD == 1, V_tot_ib_Gross * (1 - CULL/100),
                                 V_mer_ib_Sound + V_stump_ib_Sound),
         
         V_mer_ib_Sound2 = ((R_m_2 * V_tot_ib_Gross) - (R_1 * V_tot_ib_Gross)) * 
           (1 - 0/100),
         V_stump_ib_Sound2 = V_stump_ib_Gross * (1 - 0/100),
         V_stump_ob_Sound2 = V_stump_ib_Sound2 + V_stump_bk_Gross,
         V_tot_ib_Sound2 = V_mer_ib_Sound2 + V_stump_ib_Sound2,
         V_tot_bk_Sound =  V_tot_bk_Gross,
         V_tot_ob_Sound = V_tot_ib_Sound + V_tot_bk_Sound,
         V_tot_bk_Sound2 =  V_tot_ob_Sound - V_tot_ib_Sound2, 
         V_tot_ob_Sound2 = V_mer_ob_Sound2 + V_stump_ob_Sound2,
        
   
         
         V_tot_ob_Sound = ifelse(ACTUALHT == HT, V_tot_ib_Sound + V_tot_bk_Sound,
                                 V_mer_ob_Sound + V_stump_ob_Sound),
         V_tot_bk_Sound = ifelse(ACTUALHT == HT, V_tot_bk_Gross,
                                 V_tot_ob_Sound - V_tot_ib_Sound),
         
         # Snags
         V_top_ob_Sound = V_tot_ob_Sound - V_mer_ob_Sound - V_stump_ob_Sound,
         V_top_ib_Sound = V_tot_ib_Sound - V_mer_ib_Sound - V_stump_ib_Sound,
         V_top_bk = V_top_ob_Sound - V_top_ib_Sound,
        
        # Missing
        V_miss_ob_Gross = ifelse(V_tot_ob_Gross * (1 - R_m_2) >= 0, V_tot_ob_Gross * (1 - R_m_2), V_tot_ob_Gross * (1 - 0)),
        V_miss_ib_Gross = V_tot_ib_Gross * (1 - R_m_2),
        V_miss_ib_Gross2 = ifelse(is.na(V_miss_ib_Gross), 0, V_miss_ib_Gross),
        V_miss_bk_Gross = V_miss_ob_Gross - V_miss_ib_Gross2,
        V_top_ib_Sound2 = (V_tot_ib_Gross - V_mer_ib_Gross - 
                             V_stump_ib_Gross - V_miss_ib_Gross2)*(1-CULL/100),
        V_top_ob_Sound2 = V_top_ib_Sound2 + V_tot_bk_Gross * 
          (1 - R_m) - V_miss_bk_Gross,
        V_top_bk_Sound2 = V_top_ob_Sound2 - V_top_ib_Sound2,
        
        V_mer_ib_Sound3 = V_mer_ib_Gross * (1 - CULL/100),
        V_stump_ib_Sound3 = V_stump_ib_Gross * (1 - CULL/100),
        V_tot_ib_Sound3 = (V_mer_ib_Sound3 + V_stump_ib_Sound3 + V_top_ib_Sound2),
        V_tot_ob_Sound2 = (V_tot_ib_Sound3 + V_tot_bk_Gross - V_miss_bk_Gross),
        V_tot_bk_Sound2 = (V_tot_ob_Sound2 - V_tot_ib_Sound3))


## -----------------------------------------------------------------------------------------------------------------------------------------
wdsg <- read_csv("REF_SPECIES.csv") |> 
  select(SPCD, SFTWD_HRDWD, WOOD_SPGR_GREENVOL_DRYWT) |> 
  filter(SPCD <= 999) |> 
  rename(WDSG = WOOD_SPGR_GREENVOL_DRYWT)

# Enter Wood density proportions and remaining bark and branch proportions 
# for standing dead trees (Westfall et al. 2023 Table 1)
dead <- tribble(
 ~SFTWD_HRDWD, ~DECAYCD, ~DENS_PROP, ~BARK_PROP, ~BRANCH_PROP,
 "H", 0, 1, 1, 1,
 "H", 1, 0.99, 1, 1, 
 "H", 2, 0.80, 0.80, 0.50,
 "H", 3, 0.54, 0.50, 0.10,
 "H", 4, 0.43, 0.20, 0,
 "H", 5, 0.43, 0, 0,
 "S", 0, 1, 1, 1,
 "S", 1, 0.97, 1, 1,
 "S", 2, 1, 0.8, 0.5,
 "S", 3, 0.92, 0.5, 0.1,
 "S", 4, 0.55, 0.20, 0,
 "S", 5, 0.55, 0, 0
 )
tree <- tree |> 
  mutate(DECAYCD = ifelse(is.na(DECAYCD), 0, DECAYCD))
         
tree <- inner_join(tree, wdsg, by = "SPCD") 

tree <- inner_join(tree, dead, by = c("SFTWD_HRDWD", "DECAYCD")) |> 
  mutate(W_tot_ib = V_tot_ib_Gross * WDSG * 62.4,
         W_tot_ib_red = ifelse(SPCD < 300 & STATUSCD == 1, 
                               (V_tot_ib_Gross - V_miss_ib_Gross2) * 
                                 (1 - (CULL/100) * (1 - 0.92)) * WDSG * 62.4,
                               
                               ifelse(SPCD >= 300 & STATUSCD == 1,
                                      (V_tot_ib_Gross - V_miss_ib_Gross2) * 
                                        (1 - (CULL/100) * (1 - 0.54)) * WDSG * 62.4,
                               #SDTs
                                       V_tot_ib_Sound / (1 - CULL/100) * 
                                 WDSG * DENS_PROP * 62.4))) |> 
  select(-c(WDSG))


## -----------------------------------------------------------------------------------------------------------------------------------------
# Estimate total stem bark weight

bark_wt <- read_csv("Table S6a_bark_biomass_coefs_spcd.csv") |> 
  rename(MODEL = model)
bark_wt_jenkins <- read_csv("Table S6b_bark_biomass_coefs_jenkins.csv") |> 
  rename(MODEL = model) |> 
  mutate(b1 = NA)

bark_division <- bark_wt |> 
  distinct(DIVISION, SPCD, STDORGCD) |> 
  filter(!is.na(DIVISION))

bark_division_na <- bark_wt |> 
  distinct(DIVISION) |> 
  filter(!is.na(DIVISION))

spp_bark_division <- bark_wt |> 
  filter(!is.na(DIVISION)) |> 
  relocate(DIVISION) |> 
  mutate(coef_level = "SPCD/DIVISION")

bark_wt_division_na <- bark_wt |> 
  filter(is.na(DIVISION)) |> 
  select(-DIVISION)|> 
  mutate(coef_level = "SPCD")

spp_bark_division_na <- cross_join(bark_division_na, bark_wt_division_na)|> 
  arrange(SPCD)|> 
  mutate(coef_level = "SPCD")

spp_bark_wt <- rbind(spp_bark_division, spp_bark_division_na) |> 
  group_by(DIVISION, SPCD) |> 
  slice_max(coef_level) |> 
  arrange(SPCD, desc(DIVISION), STDORGCD) 

bark_wt_jenkins_spp <- inner_join(bark_wt_jenkins, ref_spp, 
                                 by  = join_by(JENKINS_SPGRPCD)) |> 
  arrange(SPCD) |> 
  mutate(coef_level = "SPGRPCD")

spp_already_have <- spp_bark_wt |> 
  group_by(SPCD) |> 
  distinct(SPCD) |> 
  mutate(SPCD_have = 1)

spp_bark_wt_jenkins <- full_join(bark_wt_jenkins_spp, spp_already_have,
                                 by = join_by(SPCD)) |> 
  filter(is.na(SPCD_have)) |> 
  cross_join(vol_division_na) |> 
  add_column(STDORGCD = NA) |> 
  select(-c(SPCD_have, JENKINS_SPGRPCD)) |> 
  relocate(DIVISION, SPCD, STDORGCD, MODEL, a, b, b1, c, coef_level)

spp_bark_wt_all <- rbind(spp_bark_wt, spp_bark_wt_jenkins) |> 
  arrange(SPCD, DIVISION)

tree <- inner_join(tree, spp_bark_wt_all) |> 
  rowwise() |> 
  mutate(W_tot_bk = get_nsvb(MODEL = MODEL, SPCD = SPCD,
                                   DIA = DIA, HT = HT,
                               a = a, b = b, b1 = b1, c = c, WDSG = NA)) |> 
  select(-(c(a, b, b1, c, MODEL, coef_level)))


## -----------------------------------------------------------------------------------------------------------------------------------------
# Estimate branch weight

branch_wt <- read_csv("Table S7a_branch_biomass_coefs_spcd.csv") |> 
  rename(MODEL = model)
branch_wt_jenkins <- read_csv("Table S7b_branch_biomass_coefs_jenkins.csv") |> 
  rename(MODEL = model) |> 
  mutate(b1 = NA)

branch_division <- branch_wt |> 
  distinct(DIVISION, SPCD, STDORGCD) |> 
  filter(!is.na(DIVISION))

branch_division_na <- branch_wt |> 
  distinct(DIVISION) |> 
  filter(!is.na(DIVISION))

spp_branch_division <- branch_wt |> 
  filter(!is.na(DIVISION)) |> 
  relocate(DIVISION) |> 
  mutate(coef_level = "SPCD/DIVISION")

branch_wt_division_na <- branch_wt |> 
  filter(is.na(DIVISION)) |> 
  select(-DIVISION)|> 
  mutate(coef_level = "SPCD")

spp_branch_division_na <- cross_join(branch_division_na, branch_wt_division_na)|> 
  arrange(SPCD)|> 
  mutate(coef_level = "SPCD")

spp_branch_wt <- rbind(spp_branch_division, spp_branch_division_na) |> 
  group_by(DIVISION, SPCD) |> 
  slice_max(coef_level) |> 
  arrange(SPCD, desc(DIVISION), STDORGCD) 

# Species reference table
ref_spp <- read_csv("REF_SPECIES.csv") |> 
  select(SPCD, JENKINS_SPGRPCD, WOOD_SPGR_GREENVOL_DRYWT) |> 
  filter(SPCD <= 999) |> 
  rename(WDSG = WOOD_SPGR_GREENVOL_DRYWT)

branch_wt_jenkins_spp <- inner_join(branch_wt_jenkins, ref_spp, 
                                 by  = join_by(JENKINS_SPGRPCD)) |> 
  arrange(SPCD) |> 
  mutate(coef_level = "SPGRPCD")

spp_already_have <- spp_branch_wt |> 
  group_by(SPCD) |> 
  distinct(SPCD) |> 
  mutate(SPCD_have = 1)

spp_branch_wt_jenkins <- full_join(branch_wt_jenkins_spp, spp_already_have,
                                 by = join_by(SPCD)) |> 
  filter(is.na(SPCD_have)) |> 
  cross_join(vol_division_na) |> 
  add_column(STDORGCD = NA) |> 
  select(-c(SPCD_have, JENKINS_SPGRPCD)) |> 
  relocate(DIVISION, SPCD, STDORGCD, MODEL, a, b, b1, c, coef_level)

spp_branch_wt_all <- rbind(spp_branch_wt, spp_branch_wt_jenkins) |> 
  arrange(SPCD, DIVISION)

tree <- inner_join(tree, spp_branch_wt_all, 
                   by = c("DIVISION", "STDORGCD", "SPCD")) |> 
  rowwise() |> 
  mutate(W_branch = get_nsvb(MODEL = MODEL, SPCD = SPCD,
                                 DIA = DIA, HT = HT,
                                 a = a, b = b, b1 = b1, c = c, 
                                 WDSG = WDSG),
         CR_H = (HT - ACTUALHT * (1 - CR/100))/HT,
         W_tot_bk_red = ifelse(ACTUALHT == HT & STATUSCD != 2, W_tot_bk, 
                               W_tot_bk * R_m_2 * DENS_PROP * BARK_PROP), 
         W_branch_red = W_branch) |> 
  select(-(c(a, b, b1, c, MODEL, coef_level)))


## -----------------------------------------------------------------------------------------------------------------------------------------
# Crowns

# This is one place where ecological province is used instead of ecological division
# Ecological division is mislabeled in Table S11_mean_crprop.csv. 
# It should be ecological province (see email to J. Westfall on 2/23/2024)

cr_prop <- read_csv("Table S11_mean_crprop.csv") |> 
  rename(SFTWD_HRDWD = `HWD Y/N`,
         MEAN_CR = `Mean CR`,
         PROVINCE = Division) |> 
  mutate(SFTWD_HRDWD = ifelse(SFTWD_HRDWD == "Y", "H", "S")) |> 
  select(-(Nobs))

eco_div_prov <- read_csv("eco_div_prov.csv") |> 
  rename(DIVISION = eco_division,
         PROVINCE = eco_province)

# Get all distinct divisions
prov_hw <- eco_div_prov |>
  distinct(PROVINCE, DIVISION) |> 
  mutate(SFTWD_HRDWD = "H")

prov_sw <- eco_div_prov |>
  distinct(PROVINCE, DIVISION) |> 
  mutate(SFTWD_HRDWD = "S")

provs <- rbind(prov_sw, prov_hw)
  
# Add UNDEFINED crown ratio if tree doesn't fall in ecoregion, by HW/SW

cr_prop2 <- full_join(provs, cr_prop, by = c("PROVINCE", "SFTWD_HRDWD")) |> 
  mutate(MEAN_CR = ifelse(is.na(MEAN_CR) & SFTWD_HRDWD == "H", 38.0, 
                          ifelse(is.na(MEAN_CR) & SFTWD_HRDWD == "S", 46.8, MEAN_CR))) |> 
  select(-DIVISION)

tree <- left_join(tree, cr_prop2, by = c("PROVINCE", "SFTWD_HRDWD")) |> 
  # Branches remaining
  mutate(Branch_Rem = ifelse(STATUSCD == 2, (ACTUALHT - HT * (1 - (MEAN_CR/100)))/(HT * (MEAN_CR/100)), 
                             (ACTUALHT - HT * (1 - CR_H))/(HT * CR_H)),
         W_branch_red = ifelse(ACTUALHT == HT, W_branch_red,
                               W_branch * DENS_PROP * BRANCH_PROP * Branch_Rem))


## -----------------------------------------------------------------------------------------------------------------------------------------
# 11. estimate total aboveground biomass

agb <- read_csv("Table S8a_total_biomass_coefs_spcd.csv") |> 
  rename(MODEL = model)
agb_jenkins <- read_csv("Table S8b_total_biomass_coefs_jenkins.csv") |> 
  rename(MODEL = model)

agb_division <- agb |> 
  distinct(DIVISION, SPCD, STDORGCD) |> 
  filter(!is.na(DIVISION))

agb_division_na <- agb |> 
  distinct(DIVISION) |> 
  filter(!is.na(DIVISION))

spp_agb_division <- agb |> 
  filter(!is.na(DIVISION)) |> 
  relocate(DIVISION) |> 
  mutate(coef_level = "SPCD/DIVISION")

agb_all_division_na <- agb |> 
  filter(is.na(DIVISION)) |> 
  select(-DIVISION)|> 
  mutate(coef_level = "SPCD")

spp_agb_division_na <- cross_join(agb_division_na, agb_all_division_na)|> 
  arrange(SPCD)|> 
  mutate(coef_level = "SPCD")

spp_agb <- rbind(spp_agb_division, spp_agb_division_na) |> 
  group_by(DIVISION, SPCD) |> 
  slice_max(coef_level) |> 
  arrange(SPCD, desc(DIVISION), STDORGCD) 

# Species reference table
ref_spp <- read_csv("REF_SPECIES.csv") |> 
  select(SPCD, JENKINS_SPGRPCD, WOOD_SPGR_GREENVOL_DRYWT) |> 
  filter(SPCD <= 999)|> 
  rename(WDSG = WOOD_SPGR_GREENVOL_DRYWT)

agb_jenkins_spp <- inner_join(agb_jenkins, ref_spp, 
                                 by  = join_by(JENKINS_SPGRPCD)) |> 
  arrange(SPCD) |> 
  mutate(coef_level = "SPGRPCD")

spp_already_have <- spp_agb |> 
  group_by(SPCD) |> 
  distinct(SPCD) |> 
  mutate(SPCD_have = 1)

spp_agb_jenkins <- full_join(agb_jenkins_spp, spp_already_have,
                                 by = join_by(SPCD)) |> 
  filter(is.na(SPCD_have)) |> 
  cross_join(vol_division_na) |> 
  add_column(a1 = NA,
             b1 = NA,
             c1 = NA,
             STDORGCD = NA) |> 
  select(-c(SPCD_have, JENKINS_SPGRPCD)) |> 
  relocate(DIVISION, SPCD, STDORGCD, MODEL, a, a1, b, b1, c, c1, coef_level)

spp_agb_all <- rbind(spp_agb, spp_agb_jenkins) |> 
  arrange(SPCD, DIVISION)

tree <- inner_join(tree, spp_agb_all) |> 
  rowwise() |> 
  mutate(AGB_pred = get_nsvb(MODEL = MODEL, SPCD = SPCD, 
                                     DIA = DIA, HT = HT,
                                     a = a, a1 = a1, b = b, 
                                     b1 = b1, c = c, c1 = c1,
                                     WDSG = WDSG),
         AGB_comp_red = W_tot_ib_red + W_tot_bk_red + W_branch_red,
         AGB_reduce = AGB_comp_red/(W_tot_ib + W_tot_bk + W_branch),
         AGB_pred_red = AGB_pred * AGB_reduce,
         AGB_diff = AGB_pred_red - AGB_comp_red,
         Wood_harm = AGB_pred_red * (W_tot_ib_red/AGB_comp_red),
         Bark_harm = AGB_pred_red * (W_tot_bk_red/AGB_comp_red),
         Branch_harm = AGB_pred_red * (W_branch_red/AGB_comp_red)) |> 
  select(-c(a, a1, b, b1, c, c1, coef_level, MODEL))


## -----------------------------------------------------------------------------------------------------------------------------------------
# 11. estimate foliage biomass

foliage <- read_csv("Table S9a_foliage_coefs_spcd.csv") |> 
  rename(MODEL = model)
foliage_jenkins <- read_csv("Table S9b_foliage_coefs_jenkins.csv") |> 
  rename(MODEL = equation)

foliage_division <- foliage |> 
  distinct(DIVISION, SPCD, STDORGCD) |> 
  filter(!is.na(DIVISION))

foliage_division_na <- foliage |> 
  distinct(DIVISION) |> 
  filter(!is.na(DIVISION))

spp_foliage_division <- foliage |> 
  filter(!is.na(DIVISION)) |> 
  relocate(DIVISION) |> 
  mutate(coef_level = "SPCD/DIVISION")

foliage_all_division_na <- foliage |> 
  filter(is.na(DIVISION)) |> 
  select(-DIVISION)|> 
  mutate(coef_level = "SPCD")

spp_foliage_division_na <- cross_join(foliage_division_na, foliage_all_division_na)|> 
  arrange(SPCD)|> 
  mutate(coef_level = "SPCD")

spp_foliage <- rbind(spp_foliage_division, spp_foliage_division_na) |> 
  group_by(DIVISION, SPCD) |> 
  slice_max(coef_level) |> 
  arrange(SPCD, desc(DIVISION), STDORGCD) 

# Species reference table
ref_spp <- read_csv("REF_SPECIES.csv") |> 
  select(SPCD, JENKINS_SPGRPCD) |> 
  filter(SPCD <= 999)

foliage_jenkins_spp <- inner_join(foliage_jenkins, ref_spp, 
                                 by  = join_by(JENKINS_SPGRPCD)) |> 
  arrange(SPCD) |> 
  mutate(coef_level = "SPGRPCD")

spp_already_have <- spp_foliage |> 
  group_by(SPCD) |> 
  distinct(SPCD) |> 
  mutate(SPCD_have = 1)

spp_foliage_jenkins <- full_join(foliage_jenkins_spp, spp_already_have,
                                 by = join_by(SPCD)) |> 
  filter(is.na(SPCD_have)) |> 
  cross_join(vol_division_na) |> 
  add_column(a1 = NA,
             b1 = NA,
             c1 = NA,
             STDORGCD = NA) |> 
  select(-c(SPCD_have, JENKINS_SPGRPCD)) |> 
  relocate(DIVISION, SPCD, STDORGCD, MODEL, a, a1, b, b1, c, c1, coef_level)

spp_foliage_all <- rbind(spp_foliage, spp_foliage_jenkins) |> 
  arrange(SPCD, DIVISION)

tree <- inner_join(tree, spp_foliage_all) |> 
  rowwise() |> 
  mutate(W_foliage = ifelse(STATUSCD == 1, get_nsvb(MODEL = MODEL, SPCD = SPCD, 
                                     DIA = DIA, HT = HT,
                                     a = a, a1 = a1, b = b, 
                                     b1 = b1, c = c, c1 = c1, WDSG = NA), 0),
         W_foliage_red = W_foliage) |> 
  select(-c(a, a1, b, b1, c, c1, coef_level, MODEL))


## -----------------------------------------------------------------------------------------------------------------------------------------
# Adjusted wood density
tree <- tree |> 
  mutate(WDSG_Adj = ifelse(ACTUALHT == HT, Wood_harm/V_tot_ib_Gross/62.4, 
                           Wood_harm/(V_tot_ib_Sound2)/62.4),
         BKSG_Adj = ifelse(ACTUALHT == HT, Bark_harm/V_tot_bk_Gross/62.4,
                            Bark_harm/(V_tot_ob_Sound2 - V_tot_ib_Sound2)/62.4),
         W_mer_ib = ifelse(ACTUALHT == HT, V_mer_ib_Gross * WDSG_Adj * 62.4, 
                           (V_tot_ib_Sound2 - V_stump_ib_Sound2 - V_top_ib_Sound) * 
                             WDSG_Adj * 62.4),
         W_mer_bk = ifelse(ACTUALHT == HT, V_mer_bk_Gross * BKSG_Adj * 62.4, 
                           (V_tot_bk_Sound - V_stump_bk_Gross - V_top_bk_Sound) * 
                             BKSG_Adj * 62.4),
         W_mer_ob = W_mer_ib + W_mer_bk,
         W_stump_ib = V_stump_ib_Gross * WDSG_Adj * 62.4,
         W_stump_bk = V_stump_bk_Gross * BKSG_Adj * 62.4,
         W_stump_ob = W_stump_ib + W_stump_bk,
         DRYBIO_TOP = AGB_pred_red - W_mer_ob - W_stump_ob)


## -----------------------------------------------------------------------------------------------------------------------------------------
# Carbon fractions
spp_live <- read_csv("Table S10a_fia_wood_c_frac_live.csv") |> 
  select(SPCD, fia.wood.c) |> 
  rename(CF = fia.wood.c) |> 
  filter(SPCD <= 999)

spp_dead <- read_csv("Table S10b_fia_wood_c_frac_dead.csv") |> 
  mutate(SFTWD_HRDWD = ifelse(`S/H` == "Hardwood", "H", "S")) |> 
  rename(DECAYCD = `Decay code`) |> 
    select(-`S/H`) |> 
  add_row(DECAYCD = c(0,0), `C fraction` = c(100,100), SFTWD_HRDWD = c("S", "H"))

tree <- inner_join(tree, spp_live)

tree <- inner_join(tree, spp_dead, by = c("SFTWD_HRDWD", "DECAYCD"))

tree <- tree |> 
  mutate(C = ifelse(STATUSCD == 1, AGB_pred_red * CF/100, 
                    AGB_pred_red * `C fraction`/100))


## -----------------------------------------------------------------------------------------------------------------------------------------
# Grab only the "key" volume, biomass, and carbon values
# Rename them to something like the FIA variable names

# tree_trim <- tree |>
#   select(EXAMPLE, SPCD, DIA, STATUSCD, V_tot_ob_Sound, AGB_pred_red, C) |> 
#   mutate(V_tot_ob_Sound = ifelse(DIA >= 5, V_tot_ob_Sound, NA)) |> 
#   rename(VOLCFSND = V_tot_ob_Sound,
#           DRYBIO_AG = AGB_pred_red,
#           CARBON_AG = C)
# tree_trim

