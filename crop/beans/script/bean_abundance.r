# Jared Adam
# BEANS abundance data: PF and Sweep nets
# started on 2/5/2024

# packages ####
library(tidyverse)
library(vegan)
library(vegan3d)
library(plotly)
# data ####
bpf <- bean_pf
unique(bpf$crop)

# wrangling test ####
# need to pivot wider to get my taxa names as columns with counts 
bpf <- bpf %>% 
  arrange(date, plot)
bpf_test <- bpf[1:95, ]

bpf_pivot <- bpf_test %>% 
  dplyr::select(-split, -life_stage, -sp, -genus) %>% 
  group_by(date, plot) %>% 
  pivot_wider(names_from = family, 
              values_from = family,
              values_fn = list(family = length))
# wrangling ####
# whole data set 
bpf_wide <- bpf %>% 
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
  relocate(year, date, crop) %>% 
  print(n = Inf)
colnames(pf_clean)

# PF 2022 ####

#
##
###


bpf_2022 <- filter(bpf_clean, year == 2022)
unique(bpf_2022$date)
colnames(bpf_2022)
bpf_2022 <- bpf_2022 %>% 
  mutate(timing = case_when(date == "2022-05-28" ~ 1,
                            date == "2022-07-01" ~ 2,
                            date == "2022-08-18" ~ 3)) %>% 
  mutate(timing = as.factor(timing)) %>% 
  dplyr::rename(Linyphiidae = Lin) %>% 
  relocate(year, date, timing)

bean_family_names_22 <- bpf_2022[7:25]
bdist_22 <- vegdist(bean_family_names_22, 'bray')

bperm_2_1 <- adonis2(bdist_22 ~ trt, permutations = 999, method = 'bray', data = bpf_2022)
bperm_2_1

# date is significant
# this makes sense
bperm_2_2 <- adonis2(bdist_22 ~ trt + date, permutations = 999, method = 'bray', data = bpf_2022)
bperm_2_2


# PF 22 #

# 3 D is better 
bord_22_3 <- metaMDS(bean_family_names_22, k = 3)
bord_22_3$stress

# plot
b_22_scrs <- scores(bord_22_3, display = "sites")
b_22_trt <- cbind(as.data.frame(b_22_scrs), timing = bpf_2022$timing)

# b_22_fsc <- as.data.frame(scores(bord_22_3, "species"))
# b_22_fsc$species <- rownames(b_22_fsc)

plot_22 <- plot_ly(b_22_trt, x = ~NMDS1, y = ~NMDS2, z = ~NMDS3, color = ~timing, 
                   colors = c("#D95F02", "#1B9E77","#E7298A"))
plot_22 <- plot_22 %>% 
  add_markers()
plot_22

# loop 

bpf_2022

bpf_2022_tot <- bpf_2022 %>% 
  mutate(Aranaeomorphae = Lycosidae + Thomisidae + Tetragnathidae + Gnaphosidae + Agelenidae +
           Linyphiidae,
         Carabid = Carabidae + Pterostichus, Cicindelidae,
         Non_Insect_Arth = Diplopoda + Chilopoda, Opiliones,
         Other_Coleoptera = Staphylinidae + Elateridae,
         Other_insects = Dermaptera) %>% 
  select(-Lycosidae, -Thomisidae, -Tetragnathidae, -Gnaphosidae, -Agelenidae, 
         -Linyphiidae, -Diplopoda, -Chilopoda, -Staphylinidae, 
         -Elateridae, -Opiliones, -Dermaptera, -Carabidae, -Pterostichus, -Cicindelidae) %>% 
  rename(Ensifera = Gryllidae,
         Caelifera = Acrididae)


sp_list <- bpf_2022_tot[7:15]
summary_list <- list()
tukey_list <- list()

for(i in 1:9){
  print(i)
  spss <- colnames(sp_list[i])
  print(spss)
  loop <- subset(bpf_2022_tot, select = c("timing", "trt", spss))
  colnames(loop) <- c("timing", "trt", "spss")
  
  model <- aov(spss ~ timing + trt, loop)
  
  aov_summary <- summary(model)
  summary_list[[i]] <- aov_summary
  
  aov_tukey <- TukeyHSD(model)
  tukey_list[[i]] <- aov_tukey
  
  
}
colnames(sp_list)
# spider = 5 carabid = 6
tukey_list[[5]]
tukey_list[[6]]

unique(bpf_2022_tot$timing)
unique(bpf_2022_tot$crop)
carab_22 <- bpf_2022_tot %>% 
  group_by(timing) %>% 
  summarise(mean = mean(Carabid), 
            sd = sd(Carabid), 
            n = n(), 
            se = sd / sqrt(n))
plot(carab_22$timing, carab_22$mean)

spider_22 <- bpf_2022_tot %>% 
  group_by(timing) %>% 
  summarise(mean = mean(Aranaeomorphae),
            sd = sd(Aranaeomorphae),
            n = n(), 
            se = sd / sqrt(n))
plot(spider_22$timing, spider_22$mean)

###
##
#

# PF 2023 ####
#
##
###


bpf_2023 <- filter(bpf_clean, year == 2023)
colnames(bpf_2023)
unique(bpf_2023$date)
bpf_2023 <- bpf_2023 %>% 
  dplyr::mutate(timing = case_when(date == "2023-06-26" ~ 1,
                                   date == "2023-07-28" ~ 2)) %>% 
  dplyr::mutate(timing = as.factor(timing)) %>% 
  dplyr::rename(Linyphiidae = Lin) %>% 
  relocate(year, date, timing)
unique(bpf_2023$timing)
bean_family_names_23 <- bpf_2023[7:25]
bdist_23 <- vegdist(bean_family_names_23, 'bray')

bperm_3_1 <- adonis2(bdist_23 ~ trt, permutations = 999, method = 'bray', data = bpf_2023)
bperm_3_1

#date is significant 
bperm_3_2 <- adonis2(bdist_23 ~ trt + date, permutations = 999, method = 'bray', data = bpf_2023)
bperm_3_2

# NMDS

# 3 D is better 
bord_23_3 <- metaMDS(bean_family_names_23, k = 3)
bord_23_3$stress


# plot

b_23_scrs <- scores(bord_23_3, display = "sites")
b_23_trt <- cbind(as.data.frame(b_23_scrs), trt = bpf_2023$trt)


b_23_fsc <- as.data.frame(scores(bord_23_3, 'species'))
b_23_fsc$species <- rownames(b_23_fsc)

b_23_date_scrs <- scores(bord_23_3, display = "sites")
b_23_date <- cbind(as.data.frame(b_23_date_scrs), time = bpf_2023$timing)

# testy<- cbind(b_23_trt, b_23_date) %>% 
#   distinct(NMDS1, NMDS2, NMDS3, trt, date) %>% 
#   mutate(date = case_when(date == "2023-06-26" ~ "1",
#                           date == "2023-07-28" ~ "2"),
#          date = as.factor(date))



# ?inner_join
# test_join <- full_join(b_23_fsc, b_23_trt)

plot_23 <- plot_ly(b_23_trt, x = ~NMDS1, y = ~NMDS2, z = ~NMDS3, color = ~trt)
plot_23 <- plot_23 %>% 
  add_markers()
plot_23


fig.23 <- plot_ly(b_23_date, x = ~NMDS1, y = ~NMDS2, z = ~NMDS3, color = ~time,
                  colors = c("#D95F02", "#1B9E77"))
fig.23 <- fig.23 %>% 
  add_markers()
fig.23

# ?htmlwidgets::saveWidget
# # checking size of the html
# widget_file_size <- function(plot_date) {
#   d <- tempdir()
#   withr::with_dir(d, htmlwidgets::saveWidget(plot_date, "index.html"))
#   f <- file.path(d, "index.html")
#   mb <- round(file.info(f)$size / 1e6, 3)
#   message("File is: ", mb," MB")
# }
# widget_file_size(plot_date)
# 
# # saving widget to folder PSA_Pennsylvania
# htmlwidgets::saveWidget(plot_date, "plant_date.html", selfcontained = F, libdir = "lib")



###
##
#


# 22 and 23 ####
colnames(bpf_clean)
unique(bpf_clean$date)
bpf_clean <- bpf_clean %>% 
  dplyr::rename(Linyphiidae = Lin)

bean_family_names <- bpf_clean[6:24]

beans_dist <- vegdist(bean_family_names, 'bray')

bpf_year <- bpf_clean %>% 
  mutate(date = as.factor(date))

bperm_1 <- adonis2(beans_dist ~ trt + year , permutations = 999, method = 'bray', data = bpf_year)
bperm_1

bperm_2 <- adonis2(beans_dist ~ year , permutations = 999, mathod = 'bray', data = bpf_year)
bperm_2

#date is significant 
bperm_3 <- adonis2(beans_dist ~ year + date + trt, permutations = 999, method = 'bray', data = bpf_year)
bperm_3

# NMDS

# these are for 22 and 23 
# 3 D is better 
bord_3 <- metaMDS(bean_family_names, k = 3)
bord_3$stress

# plot 

b_scrs <- scores(bord_3, display = "sites")
b_trt <- cbind(as.data.frame(b_scrs), trt = bpf_year$trt)


b_fsc <- as.data.frame(scores(bord_3, 'species'))
b_fsc$species <- rownames(b_fsc)

b_years <- scores(bord_3 , display = "sites")
b_years <- cbind(as.data.frame(b_years), year = bpf_year$year)

plot_year <- plot_ly(b_years, x = ~NMDS1, y = ~NMDS2, z = ~NMDS3, color = ~year,
                     colors = c("#D95F02", "#1B9E77"))
plot_year <- plot_year %>% 
  add_markers()
plot_year

##
#

