# packages ####
library(tidyverse)
library(vegan)
library(vegan3d)
library(ggpubr)
library(RColorBrewer)

# data ####
micros <- CE2_counts
micros

corn_pf
bean_pf

# pf wrangling ####

# KARN #

cpf_wide <- corn_pf %>% 
  dplyr::select(-split, -life_stage, -sp, -genus) %>% 
  group_by(date, plot) %>% 
  pivot_wider(names_from = family, 
              values_from = family,
              values_fn = list(family = length)) %>% 
  print(n = Inf)

colnames(cpf_wide)
cpf_wide <- cpf_wide  %>% 
  replace(is.na(.),0) %>% 
  mutate(Lyn = Liniphiidae + Lyniphiidae + Linyphiidae, 
         Staph= Staphylinidae + Staphylinidaa) %>% 
  dplyr::select(-Liniphiidae, -Lyniphiidae, -Linyphiidae, -Staphylinidae, -Staphylinidaa, -na) %>% 
  mutate(date = as.Date(date, "%m/%d/%Y"), 
         year = format(date, "%Y")) %>% 
  relocate(year) %>% 
  mutate(year = as.factor(year)) %>% 
  mutate_at(3:5, as.factor) 
colnames(pf_wide)

cpf_clean <- cpf_wide %>% 
  mutate(trt = as.factor(case_when(plot %in% c(101,203,304,401,503) ~ 1,
                                   plot %in% c(103,204,302,403,501) ~ 2,
                                   plot %in% c(102,201,303,402,502) ~ 3, 
                                   plot %in% c(104,202,301,404,504) ~ 4))) %>% 
  na.omit() %>%
  print(n = Inf)
colnames(cpf_clean)

c_clean <- cpf_clean %>% 
  rename(Lyniphiidae = Lyn,
         Staphylinidae = Staph, 
         Tetragnathidae = Tetrgnathidae) %>% 
  mutate(Carabidae_new = Carabidae + Cicindelidae,
         Gryll = Gryllidae +Gyrillidae) %>% 
  select(-Carabidae, -Cicindelidae, -Gryllidae, -Gyrillidae) %>% 
  rename(Carabidae = Carabidae_new,
         Gryllidae = Gryll) %>%
  print(n = Inf) 



# BEAN#

bpf_wide <- bean_pf %>% 
  dplyr::select(-split, -life_stage, -sp, -genus) %>% 
  group_by(date, plot) %>% 
  pivot_wider(names_from = family, 
              values_from = family,
              values_fn = list(family = length)) %>% 
  print(n = Inf)

colnames(bpf_wide)
bpf_wide <- bpf_wide  %>% 
  replace(is.na(.),0) %>% 
  mutate(Lin = Liniphiide + Lyniphiidae + Linyphiidae) %>% 
  dplyr::select(-Liniphiide, -Lyniphiidae, -Linyphiidae, -na) %>% 
  mutate(date = as.Date(date, "%m/%d/%Y"), 
         year = format(date, "%Y")) %>% 
  relocate(year) %>% 
  mutate(year = as.factor(year)) %>% 
  mutate_at(3:5, as.factor) 
colnames(bpf_wide)

bpf_clean <- bpf_wide %>% 
  mutate(trt = as.factor(case_when(plot %in% c(101,203,304,401,503) ~ 1,
                                   plot %in% c(103,204,302,403,501) ~ 2,
                                   plot %in% c(102,201,303,402,502) ~ 3, 
                                   plot %in% c(104,202,301,404,504) ~ 4))) %>% 
  na.omit() %>%  
  dplyr::select(-crop) %>% 
  mutate(crop = 'beans',
         crop = as.factor(crop)) %>% 
  relocate(year, date, crop, trt, plot) %>% 
  print(n = Inf)
colnames(bpf_clean)


b_clean <- bpf_clean %>% 
  rename('Coleoptera larvae' = Coleoptera)%>% 
  rename(Lyniphiidae = Lin) %>%
  mutate(Carabidae_new = Carabidae + Pterostichus +Cicindelidae) %>% 
  select(-Carabidae, -Pterostichus, -Cicindelidae) %>% 
  rename(Carabidae = Carabidae_new) %>% 
  print(n = Inf)


pf_all <- rbind(b_clean, c_clean) %>% 
  replace(is.na(.), 0) %>% 
  mutate_at(vars(6:25), as.numeric)
colnames(pf_all)


pf_clean <- pf_all %>% 
  dplyr::select(-Elateridae, -Diplopoda, -Dermaptera, -Acrididae, -Coreidae) %>% 
  mutate(predators = Lycosidae + Formicidae + Thomisidae + `Coleoptera larvae` + Staphylinidae + Opiliones + Gryllidae +
           Tetragnathidae + Chilopoda  + Gnaphosidae + Agelenidae + Lyniphiidae + Carabidae + Araneae + Salticidae) %>% 
  dplyr::select(year, crop, trt, predators) %>% 
  ungroup() %>% 
  group_by(crop, year, trt) %>% 
  summarise(pred = sum(predators))

# micro wrangling ####
colnames(micros)
unique(micros$date)

?distinct
# eliminating the duplicated rows
micros_ready <- micros %>% 
  mutate_at(vars(4:41), as.numeric) %>% 
  group_by(date, crop, plot) %>% 
  distinct(date, .keep_all = TRUE) %>% 
  ungroup() %>% 
  print(n = Inf)

# need to add treatment in now
micros_set <- micros_ready %>% 
  mutate(plot = replace(plot, plot == 507, 502)) %>% # there is a sneaky 507 plot number
  mutate(trt = case_when(plot %in% c(101,203,304,401,503) ~ 'Check',
                         plot %in% c(102,201,303,402,502) ~ 'Green',
                         plot %in% c(103,204,302,403,501) ~ 'Brown',
                         plot %in% c(104,202,301,404,504) ~ 'Gr-Br')) %>% 
  mutate_at(vars(1:3), as.factor) %>% 
  mutate_at(vars(43), as.factor) %>% 
  filter(!row_number() %in% c(46,47,71,83)) %>% # these rows are all NA, so when I replace with 0, they become all 0 and then vegdist cannot function. removing them early
  replace(is.na(.),0) %>% 
  print(n = Inf)
# check to make sure these changes worked
colnames(micros_set)
unique(micros_set$trt)
unique(micros_set$plot)
which(micros_set$trt == 'NA')
which(micros_set$trt == 'Green')
class(micros_set$trt)
