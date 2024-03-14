# Jared Adam 
# beans slugs = 2022 and 2023
# started on the plane 
# adding here slug populations models and figs
# slug x predator regressions and plots 

# packages ####
library(tidyverse)
library(MASS)
library(performance)
library(lme4)
library(emmeans)
library(lmtest)


# data ####
slugs <- slugs_beans_all %>% 
  mutate(slug_count = as.numeric(slug_count)) %>% 
  rename(precip = '7_day_precip_in') %>% 
  mutate(temp = as.numeric(temp)) %>% 
  mutate(treatment = case_when(plot %in% c(101,203,304,401,503) ~ 1,
                               plot %in% c(103,204,302,403,501) ~ 2,
                               plot %in% c(102,201,303,402,502) ~ 3, 
                               plot %in% c(104,202,301,404,504) ~ 4)) %>% 
  mutate(block = case_when(plot %in% c(101,102,103,104) ~ 1,
                           plot %in% c(201,202,203,204) ~ 2,
                           plot %in% c(301,302,303,304) ~ 3,
                           plot %in% c(401,402,403,404) ~ 4,
                           plot %in% c(501,502,503,504) ~ 5)) %>% 
  mutate(block = as.factor(block)) %>%
  dplyr::select(-location, -shingle_id, -time, -temp, -row) %>% 
  mutate(date = as.Date(date, "%m/%d/%Y"),
         year = format(date, '%Y'))  %>% 
  dplyr::select(-date) %>% 
  mutate(year = as.factor(year), 
       treatment = as.factor(treatment))%>% 
  rename(season = seaon) %>% 
  mutate(season = case_when(season == "fall" ~ "Fall",
                            season == "spring" ~ "Spring"))%>% 
  group_by(season, year, month, plot, treatment, block) %>% 
  summarise(total_slug =  sum(slug_count))%>% 
  print(n = Inf)
slugs <- slugs[1:160,]
slugs <- slugs %>% 
  replace(is.na(.),0) %>% 
  print(n = Inf)
unique(slugs$treatment)
unique(slugs$season)

# getting precip 
slug_precip <- slugs_beans_all %>% 
  mutate(slug_count = as.numeric(slug_count)) %>% 
  rename(precip = '7_day_precip_in') %>% 
  mutate(temp = as.numeric(temp)) %>% 
  mutate(treatment = case_when(plot %in% c(101,203,304,401,503) ~ 1,
                               plot %in% c(103,204,302,403,501) ~ 2,
                               plot %in% c(102,201,303,402,502) ~ 3, 
                               plot %in% c(104,202,301,404,504) ~ 4)) %>% 
  mutate(block = case_when(plot %in% c(101,102,103,104) ~ 1,
                           plot %in% c(201,202,203,204) ~ 2,
                           plot %in% c(301,302,303,304) ~ 3,
                           plot %in% c(401,402,403,404) ~ 4,
                           plot %in% c(501,502,503,504) ~ 5)) %>% 
  mutate(block = as.factor(block)) %>%
  dplyr::select(-location, -shingle_id, -time, -temp, -row) %>% 
  mutate(date = as.Date(date, "%m/%d/%Y"),
         year = format(date, '%Y'))  %>% 
  dplyr::select(-date) %>% 
  mutate(year = as.factor(year), 
         treatment = as.factor(treatment))%>% 
  rename(season = seaon) %>% 
  mutate(season = case_when(season == "fall" ~ "Fall",
                            season == "spring" ~ "Spring"))%>% 
  group_by(year, season, month, plot) %>% 
  summarise(sum_pre = sum(precip)) %>% 
  print(n = Inf)
slug_precip <- slug_precip[1:160,]
slug_precip <- slug_precip %>% 
  replace(is.na(.),0) %>%
  ungroup() %>% 
  dplyr::select(sum_pre) %>% 
  print(n = Inf)
  
final_slug <- cbind(slug_precip, slugs) 

final_slug <- final_slug %>% 
  mutate_at(vars(2:7), as.factor) %>% 
  relocate(season, year, month, plot, treatment, block)
  as_tibble()

#subset by season

fall_slugs <- subset(slugs, season == "fall")
spring_slugs <- subset(slugs, season == "spring")
bs_22 <- subset(slugs, year == "2022")
bs_23 <- subset(slugs, year == "2023")

# models ####

# look at overdispersion: variance > mean?
dispersion_stats <- slugs %>% 
  group_by(treatment) %>%
  summarise(
    mean = mean(total_slug, na.rm=TRUE),
    variances = var(total_slug, na.rm=TRUE),
    ratio = variances/mean) 
if(dispersion_stats$mean[1] > dispersion_stats$variances[1] & 
   dispersion_stats$mean[2] > dispersion_stats$variances[2] &
   dispersion_stats$mean[3] > dispersion_stats$variances[3] &
   dispersion_stats$mean[4] > dispersion_stats$variances[4]){
  print("run a poisson, probs")
  } else {
    print("these jawns overdispersed")
  }



# let's see which is better, poisson or nb? 
# run one of each where the only difference is the family 
poisson_model <- glmer(total_slug ~ treatment + 
                         (1|year/block), 
                       data = slugs, 
                       family = poisson)

nb_model_trt <- glmer.nb(total_slug ~ treatment + 
                           (1|year/block), 
                         data = final_slug) 

lrtest(poisson_model,nb_model_trt)
# the negative binomial has the higher likelihood score, so we will use that

#actual model: 
# with precip, the model was overfit and not getting an r2 value 
unique(final_slug$season)
is.factor(final_slug$season)
final_slug <- final_slug %>% 
  mutate(season = as.factor(season))

m0 <- glmer.nb(total_slug ~ 
                      (1|year/season/block), 
                    data = final_slug)


m1 <- glmer.nb(total_slug ~ treatment + (1|year/season/block), 
                    data = final_slug)

bsl.table <- as.data.frame(summary(m1)$coefficients)
#CI <- confint(m1)
bsl.table <-cbind(row.names(bsl.table), bsl.table)
names(bsl.table) <- c("Term", "B", "SE", "t", "p")
nice_table(bsl.table, highlight = TRUE)


anova(m0, m1)

summary(m1)
r2_nakagawa(m1)
# Conditional R2: 0.734
# Marginal R2: 0.010
binned_residuals(m1)
br_1 <- binned_residuals(m1)
plot(br_1)
s_emm <- emmeans(m1, ~treatment, type = "response")
pairs(s_emm)
cld(s_emm, Letters = letters)

# no season
m1_no_season <- glmer.nb(total_slug ~ treatment + (1|year/block), 
               data = final_slug)
r2_nakagawa(m1_no_season)
# Conditional R2: 0.118
# Marginal R2: 0.017

# plots for slug populations  ####
# add sig values in ppt: confusing with two factor facets
slugs$szn <- factor(slugs$season, levels = c("Spring", "Fall"))
ggplot(slugs, aes(x = as.character(treatment), y = total_slug, fill = treatment))+
  geom_boxplot(alpha = 0.7)+
  facet_wrap(~year + szn, scales = "free_y")+
  scale_fill_manual(values = c("#E7298A", "#D95F02", "#1B9E77", "#7570B3"))+
  scale_x_discrete(limits = c("1", "2", "4", "3"),
                   labels=c("No CC", "14-21 DPP", "3-7 DPP", "1-3 DAP"))+
  labs( x = 'Treatment',
        y = 'Total Slug Counts', 
        title = "Soybean: Total Slugs by Treatment",
        subtitle = " Years: 2022-2023")+
  theme(legend.position = "none",
        axis.text.x = element_text(size=18),
        axis.text.y = element_text(size = 18),
        strip.text = element_text(size = 16),
        axis.title = element_text(size = 20),
        plot.title = element_text(size = 20),
        plot.subtitle = element_text(size = 16), 
        panel.grid.major.y = element_line(color = "darkgrey"),
        panel.grid.major.x = element_blank(),
        panel.grid.minor = element_blank())

slug_plot <- final_slug %>% 
  group_by(treatment) %>% 
  summarise(mean = mean(total_slug), 
            sd = sd(total_slug), 
            n = n(), 
            se = sd/sqrt(n))

ggplot(slug_plot, aes(x = treatment, y = mean, fill = treatment))+
  geom_bar(stat = "identity", position = "dodge", alpha = 0.7)+
  geom_errorbar(aes(x = treatment,ymin = mean - se, ymax = mean + se),
                color = "black", alpha = 1, width = 0.2, linewidth = 1)+
  scale_fill_manual(values = c("#E7298A", "#D95F02", "#1B9E77", "#7570B3"))+
  scale_x_discrete(limits = c("1", "2", "4", "3"),
                   labels=c("No CC", "14-28 DPP", "3-7 DPP", "1-3 DAP"))+
  labs( x = 'Treatment',
        y = 'Total Slug Counts', 
        title = "Soybean: Average Slug Counts / Trap x Treatment",
        subtitle = " Years: 2022-2023",
        caption = "DPP: Days pre plant
DAP : Days after plant")+
  theme(legend.position = "none",
        axis.text.x = element_text(size=26),
        axis.text.y = element_text(size = 26),
        axis.title = element_text(size = 32),
        plot.title = element_text(size = 28),
        plot.subtitle = element_text(size = 24), 
        panel.grid.major.y = element_line(color = "darkgrey"),
        panel.grid.major.x = element_blank(),
        panel.grid.minor = element_blank(),
        plot.caption = element_text(hjust = 0, size = 20, color = "grey25"))

# pub plots ####

ggplot(slug_plot, aes(x = treatment, y = mean))+
  geom_bar(stat = "identity", position = "dodge", alpha = 0.7)+
  geom_errorbar(aes(x = treatment,ymin = mean - se, ymax = mean + se),
                color = "black", alpha = 1, width = 0.2, linewidth = 1)+
  scale_x_discrete(limits = c("1", "2", "4", "3"),
                   labels=c("No CC", "14-28 DPP", "3-7 DPP", "1-3 DAP"))+
  labs( x = 'Treatment',
        y = 'Total Slug Counts', 
        title = "Soybean: Average Slug Counts / Trap x Treatment",
        subtitle = " Years: 2022-2023",
        caption = "DPP: Days pre plant
DAP : Days after plant")+
  theme(legend.position = "none",
        axis.text.x = element_text(size=26),
        axis.text.y = element_text(size = 26),
        axis.title = element_text(size = 32),
        plot.title = element_text(size = 28),
        plot.subtitle = element_text(size = 24), 
        panel.grid.major.y = element_line(color = "darkgrey"),
        panel.grid.major.x = element_blank(),
        panel.grid.minor = element_blank(),
        plot.caption = element_text(hjust = 0, size = 20, color = "grey25"))























