# Jared Adam 
# sent prey for beans 
# on a plain
# revisiting 2/14/2024

# packages ####
library(tidyverse)
library(MASS)
library(performance)
library(lme4)
library(emmeans)
library(lmtest)
library(nlme)
library(multcomp)

# data ####
beans_sent <- sent_prey_beans_all

colnames(beans_sent)
sent_years <- beans_sent %>% 
  mutate(date = as.Date(date, "%m/%d/%Y"),
         year = format(date, '%Y')) %>% 
  dplyr::select(-location, -date) %>% 
  rename(plot_id = ploitid) %>% 
  relocate(year, growth_stage, plot_id, block, treatment, row, sample, pm.absent, pm.partial, n.pred, 
          am.absent, am.partial, d.pred, to.predated, pm.weather, am.weather)%>%
  mutate(n.pred = as.double(n.pred),
         d.pred = as.double(d.pred),
         to.predated = as.double(to.predated)) %>% 
  mutate(growth_stage = as.factor(growth_stage)) %>%
  mutate_at(vars(1:5), as_factor) %>% 
  print(n = Inf)

sent_years %>% 
  dplyr::select(growth_stage, treatment, to.predated) %>% 
  filter(growth_stage == 'R3') %>% 
  print(n = Inf)


pred_tot <- sent_years %>% 
  dplyr::select(-pm.absent, -pm.partial, -am.absent, -am.partial, -d.pred, -n.pred)
  
 
  
sent_prop <- beans_sent %>% 
  mutate(date = as.Date(date, "%m/%d/%Y"),
         year = format(date, '%Y')) %>% 
  dplyr::select(-location, -date) %>% 
  rename(plot_id = ploitid) %>% 
  group_by(growth_stage, treatment) %>% 
  summarise(prop = mean(to.predated),
            sd = sd(to.predated),
            n = n(),
            se = sd/sqrt(n)) %>% 
  print(n= Inf)


# subset by year and then growth stage 
sent_22 <- subset(sent_years, year == '2022')
sent_23 <- subset(sent_years, year == '2023')

# models all ####
sent_years <- sent_years %>% 
  mutate_at(vars(1:5), as_factor)

m0 <- glmer(to.predated ~ 
              (0+growth_stage|block/plot_id),
            data = sent_years,
            family = binomial)

m1 <- glmer(to.predated ~ treatment +
              (0+growth_stage|block/plot_id),
            data = sent_years,
            family = binomial)

m2 <- glmer(to.predated ~ treatment + growth_stage +
              (0+growth_stage|block/plot_id),
            data = sent_years,
            family = binomial)

m3 <- glmer(to.predated ~ treatment*growth_stage +
              (growth_stage|block/plot_id),
            data = sent_years,
            family = binomial)

isSingular(m3)
rePCA(m3)

?isSingular
?rePCA
?lme4::convergence
?lme4::troubleshooting

gm_all <- allFit(m3)
ss <- summary(gm_all)
ss$which.OK
ss$llik

anova(m0 , m1, m2, m3)
# npar    AIC    BIC  logLik deviance  Chisq Df Pr(>Chisq)   
# m0   13 477.28 536.81 -225.64   451.28                        
# m1   16 467.68 540.94 -217.84   435.68 15.607  3   0.001365 **
# m2   18 464.96 547.39 -214.48   428.96  6.715  2   0.034822 * 
# m3   24 469.34 579.25 -210.67   421.34  7.616  6   0.267610  
check_model(m3)
binned_residuals(m3)
hist(residuals(m3))

cld(emmeans(m3, ~treatment), Letters = letters)
# treatment emmean      SE  df asymp.LCL asymp.UCL .group
# 1           1.67   0.230 Inf      1.22      2.12  a    
# 2           2.60   0.303 Inf      2.00      3.19  ab   
# 3           3.35   0.450 Inf      2.47      4.23   b   
# 4           7.61 727.076 Inf  -1417.44   1432.65  ab   

cld(emmeans(m3, ~growth_stage), Letters = letters)
# growth_stage emmean      SE  df asymp.LCL asymp.UCL .group
# V3             1.64   0.302 Inf      1.05      2.23  a    
# V5             2.50   0.279 Inf      1.95      3.04   b   
# R3             7.28 545.307 Inf  -1061.50   1076.07  ab 


# bent.table <- as.data.frame(summary(m3)$coefficients)
# #CI <- confint(m1)
# bent.table <-cbind(row.names(bent.table), bent.table)
# names(bent.table) <- c("Term", "B", "SE", "t", "p")
# nice_table(bent.table, highlight = TRUE)


# plot for total/ all data ####

trt_prop <- beans_sent %>% 
  mutate(date = as.Date(date, "%m/%d/%Y"),
         year = format(date, '%Y')) %>% 
  dplyr::select(-location, -date) %>% 
  group_by(treatment, ploitid) %>% 
  summarise(prop = mean(to.predated),
            sd = sd(to.predated),
            n = n(),
            se = sd/sqrt(n)) %>% 
  mutate_at(vars(1), factor) %>% 
  print(n= Inf)

ggplot(trt_prop, aes(x = treatment, y =  prop))+
  geom_point(aes(color = treatment), size = 10)+
  geom_errorbar(aes(x = treatment,ymin = prop - se, ymax = prop + se),
                color = "black", alpha = 1, width = 0.2, linewidth = 1)+
  scale_x_discrete(labels=c("No CC", "Early", "Late", "Green"),
                   limits = c("1", "2", "4", "3"))+ 
  scale_color_manual(values = c("#E7298A", "#D95F02", "#1B9E77", "#7570B3"))+
  labs(
    title = "Soybean: Mean predation x Treatment",
    subtitle = "Years: 2022-2023",
    x = "Treatment termination",
    y = "Mean proportion predated ( x / 1 )"
#     caption = "DPP: Days pre plant
# DAP: Days after plant"
  )+
  theme(legend.position = 'none',
        axis.title = element_text(size = 32),
        plot.subtitle = element_text(size = 24),
        plot.title = element_text(size = 28),
        # axis.line = element_line(size = 1.25),
        # axis.ticks = element_line(size = 1.25),
        # axis.ticks.length = unit(.25, "cm"),
        axis.text.x = element_text(size = 32),
        axis.text.y = element_text(size = 26), 
        # panel.grid.major.y = element_line(color = "darkgrey"),
        panel.grid.major.x = element_blank(),
        panel.grid.minor = element_blank(),
        plot.caption = element_text(hjust = 0, size = 20, color = "grey25"))+
  annotate("text", x = 1, y = .98, label = "a", size = 10)+ #1
  annotate("text", x = 2, y = .98, label = "bc", size = 10)+ #2
  annotate("text", x = 3, y = .98, label = "b", size = 10)+ #4
  annotate("text", x = 4, y = .98, label = "c", size = 10) #3

# treatment emmean      SE  df asymp.LCL asymp.UCL .group
# 1           1.67   0.230 Inf      1.22      2.12  a    
# 2           2.60   0.303 Inf      2.00      3.19  ab   
# 3           3.35   0.450 Inf      2.47      4.23   b   
# 4           7.61 727.076 Inf  -1417.44   1432.65  ab   
ggplot(trt_prop, aes(x = treatment, y = prop, fill = treatment))+
  geom_boxplot(alpha = 0.7)+
  scale_x_discrete(labels=c("No CC", "Early", "Late", "Green"),
                   limits = c("1", "2", "4", "3"))+ 
  scale_fill_manual(values = c("#E7298A", "#D95F02", "#1B9E77", "#7570B3"))+
  labs(
    title = "Soybean: Mean predation x Treatment",
    subtitle = "Years: 2022-2023",
    x = "Treatment termination",
    y = "Mean proportion predated ( x / 1 )"
  )+
  theme(legend.position = 'none',
        axis.title = element_text(size = 32),
        plot.subtitle = element_text(size = 24),
        plot.title = element_text(size = 28),
        # axis.line = element_line(size = 1.25),
        # axis.ticks = element_line(size = 1.25),
        # axis.ticks.length = unit(.25, "cm"),
        axis.text.x = element_text(size = 32),
        axis.text.y = element_text(size = 26), 
        panel.grid.major.y = element_line(color = "darkgrey"),
        panel.grid.major.x = element_blank(),
        panel.grid.minor = element_blank())+
  annotate("text", x = 1, y = 1, label = "a", size = 10)+ #1
  annotate("text", x = 2, y = 1, label = "ab", size = 10)+ #2
  annotate("text", x = 3, y = 1, label = "ab", size = 10)+ #4
  annotate("text", x = 4, y = 1, label = "b", size = 10)+ #3
  scale_y_continuous(limits = c(0,1))


vgs_prop <- beans_sent %>% 
  mutate(date = as.Date(date, "%m/%d/%Y"),
         year = format(date, '%Y')) %>% 
  dplyr::select(-location, -date) %>% 
  group_by(growth_stage) %>% 
  summarise(prop = mean(to.predated),
            sd = sd(to.predated),
            n = n(),
            se = sd/sqrt(n)) %>% 
  mutate_at(vars(1), factor) %>% 
  print(n= Inf)

ggplot(gs_prop, aes(x = growth_stage, y =  prop))+
  geom_point(aes(color = growth_stage), size = 10)+
  geom_errorbar(aes(x = growth_stage,ymin = prop - se, ymax = prop + se),
                color = "black", alpha = 1, width = 0.2, linewidth = 1)+
  scale_x_discrete(limits = c("V3", "V5", "R3"))+ 
  scale_color_manual(values = c("#E7298A", "#D95F02", "#1B9E77"))+
  labs(
    title = "Soybean: Mean predation x Growth Stage",
    subtitle = "Years: 2022-2023",
    x = "Growth Stage",
    y = "Mean proportion predated ( x / 1 )"
  )+
  theme(legend.position = 'none',
        axis.title = element_text(size = 32),
        plot.subtitle = element_text(size = 24),
        plot.title = element_text(size = 28),
        # axis.line = element_line(size = 1.25),
        # axis.ticks = element_line(size = 1.25),
        # axis.ticks.length = unit(.25, "cm"),
        axis.text.x = element_text(size = 32),
        axis.text.y = element_text(size = 26), 
        panel.grid.major.y = element_line(color = "darkgrey"),
        panel.grid.major.x = element_blank(),
        panel.grid.minor = element_blank())+
  annotate("text", x = 1, y = 0.99, label = "a", size = 10)+
  annotate("text", x = 2, y = 0.99, label = "b", size = 10)+
  annotate("text", x = 3, y = 0.99, label = "b", size = 10)

gs_prop <- beans_sent %>% 
  mutate(date = as.Date(date, "%m/%d/%Y"),
         year = format(date, '%Y')) %>% 
  dplyr::select(-location, -date) %>% 
  group_by(growth_stage,ploitid) %>% 
  summarise(prop = mean(to.predated),
            sd = sd(to.predated),
            n = n(),
            se = sd/sqrt(n)) %>% 
  mutate_at(vars(1), factor) %>% 
  print(n= Inf)
# growth_stage emmean      SE  df asymp.LCL asymp.UCL .group
# V3             1.64   0.302 Inf      1.05      2.23  a    
# V5             2.50   0.279 Inf      1.95      3.04   b   
# R3             7.28 545.307 Inf  -1061.50   1076.07  ab 
ggplot(gs_prop, aes(x = growth_stage, y = prop, fill = growth_stage))+
  geom_boxplot(alpha = 0.7)+
  scale_x_discrete(limits = c("V3", "V5", "R3"))+ 
  scale_fill_manual(values = c("#E7298A", "#D95F02", "#1B9E77"))+
  labs(
    title = "Soybean: Mean predation x gs",
    subtitle = "Years: 2022-2023",
    x = "Growth Stage",
    y = "Mean proportion predated ( x / 1 )"
  )+
  theme(legend.position = 'none',
        axis.title = element_text(size = 32),
        plot.subtitle = element_text(size = 24),
        plot.title = element_text(size = 28),
        # axis.line = element_line(size = 1.25),
        # axis.ticks = element_line(size = 1.25),
        # axis.ticks.length = unit(.25, "cm"),
        axis.text.x = element_text(size = 32),
        axis.text.y = element_text(size = 26), 
        panel.grid.major.y = element_line(color = "darkgrey"),
        panel.grid.major.x = element_blank(),
        panel.grid.minor = element_blank())+
  annotate("text", x = 1, y = .98, label = "a", size = 10)+
  annotate("text", x = 2, y = .98, label = "b", size = 10)+
  annotate("text", x = 3, y = .98, label = "ab", size = 10)+
  scale_y_continuous(limits = c(0,1))

# pub plots ####

ggplot(trt_prop, aes(x = treatment, y =  prop))+
  geom_point(size = 10)+
  geom_errorbar(aes(x = treatment,ymin = prop - se, ymax = prop + se),
                color = "black", alpha = 1, width = 0.2, linewidth = 1)+
  scale_x_discrete(labels=c("No CC", "14-28 DPP", "3-7 DPP", "1-3 DAP"),
                   limits = c("1", "2", "4", "3"))+ 
  labs(
    title = "Soybean: Mean predation x Treatment",
    subtitle = "Years: 2022-2023",
    x = "Treatment",
    y = "Mean proportion predated ( x / 1 )",
    caption = "DPP: Days pre plant
DAP: Days after plant"
  )+
  theme(legend.position = 'none',
        axis.title = element_text(size = 32),
        plot.subtitle = element_text(size = 24),
        plot.title = element_text(size = 28),
        # axis.line = element_line(size = 1.25),
        # axis.ticks = element_line(size = 1.25),
        # axis.ticks.length = unit(.25, "cm"),
        axis.text.x = element_text(size = 26),
        axis.text.y = element_text(size = 26), 
        panel.grid.major.y = element_line(color = "darkgrey"),
        panel.grid.major.x = element_blank(),
        panel.grid.minor = element_blank(),
        plot.caption = element_text(hjust = 0, size = 20, color = "grey25"))+
  annotate("text", x = 1, y = .855, label = "a", size = 10)+ #1
  annotate("text", x = 2, y = .955, label = "ab", size = 10)+ #2
  annotate("text", x = 3, y = .92, label = "ab", size = 10)+ #4
  annotate("text", x = 4, y = .98, label = "b", size = 10) #3

ggplot(gs_prop, aes(x = growth_stage, y =  prop))+
  geom_point(size = 10)+
  geom_errorbar(aes(x = growth_stage,ymin = prop - se, ymax = prop + se),
                color = "black", alpha = 1, width = 0.2, linewidth = 1)+
  scale_x_discrete(limits = c("V3", "V5", "R3"))+ 
  labs(
    title = "Soybean: Mean predation x Growth Stage",
    subtitle = "Years: 2022-2023",
    x = "Growth Stage",
    y = "Mean proportion predated ( x / 1 )"
  )+
  theme(legend.position = 'none',
        axis.title = element_text(size = 32),
        plot.subtitle = element_text(size = 24),
        plot.title = element_text(size = 28),
        # axis.line = element_line(size = 1.25),
        # axis.ticks = element_line(size = 1.25),
        # axis.ticks.length = unit(.25, "cm"),
        axis.text.x = element_text(size = 26),
        axis.text.y = element_text(size = 26), 
        panel.grid.major.y = element_line(color = "darkgrey"),
        panel.grid.major.x = element_blank(),
        panel.grid.minor = element_blank())+
  annotate("text", x = 1, y = 0.845, label = "a", size = 10)+
  annotate("text", x = 2, y = 0.94, label = "b", size = 10)+
  annotate("text", x = 3, y = 0.99, label = "ab", size = 10)

# old plots ####
# m1_plot
# ggplot(m1_plot, aes(x = factor(treatment), y = prob, shape = growth_stage))+
#   geom_point(aes(color = factor(treatment)), alpha = 1, size = 5, position = position_dodge(width = .75))+
#   geom_errorbar(aes(x = factor(treatment),ymin = prob - SE, ymax = prob + SE),
#                 color = "black", alpha = 1, width = 0, linewidth = 1.5)+
#   geom_errorbar(aes(x = factor(treatment),ymin = asymp.LCL, ymax = asymp.UCL), 
#                 alpha = .6, width = 0, linewidth = 1)+
#   scale_x_discrete(labels=c("Check","Brown","Green","GrBr"))+ 
#   scale_color_manual(values = c("#E7298A", "#D95F02", "#1B9E77", "#7570B3"))+
#   theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 18), 
#         axis.text.y = element_text(size = 20),
#         axis.line = element_line(color = "black", size = 1.25))+
#   annotate("text", x = 2, y = 1.01, label = "p = 0.00107**", size = 6)+
#   annotate("text", x = 3, y = 1.01, label = "p = 2.04e-05***", size = 6)+
#   annotate("text", x = 4, y = 1.01, label = "p = 0.03882*", size = 6)+
#   labs(
#     title = "Beans: Mean predation",
#     subtitle = "Years: 2022-2023",
#     y = "Mean predation",
#     x = "Treatment"
#   )+
#   theme(legend.position = 'none',
#         axis.title = element_text(size = 20),
#         plot.subtitle = element_text(size = 18),
#         plot.title = element_text(size = 24),
#         axis.line = element_line(size = 1.25),
#         axis.ticks = element_line(size = 1.25),
#         axis.ticks.length = unit(.25, "cm"),
#         panel.grid.major = element_blank(),
#         panel.grid.minor = element_blank()
#   )

ggplot(sent_prop, aes(x = factor(growth_stage, level = c("V3", "V5", "R3")), y =  prop))+
  geom_point(aes(size = 5))+
  geom_errorbar(aes(x = factor(growth_stage),ymin = prop - se, ymax = prop + se),
                color = "black", alpha = 1, width = 0.2, linewidth = 1)+
  labs(
    title = "Beans: Mean predation",
    subtitle = "Years: 2022-2023",
    x = "Growth Stage",
    y = "Mean proportion predated (x/1)"
  )+
  annotate("text", x = 1, y = 0.84, label = "p = 0.000571 ***", size = 6)+
  theme(legend.position = 'none',
        axis.title = element_text(size = 20),
        plot.subtitle = element_text(size = 18),
        plot.title = element_text(size = 24),
        axis.line = element_line(size = 1.25),
        axis.ticks = element_line(size = 1.25),
        axis.ticks.length = unit(.25, "cm"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        axis.text.x = element_text(size = 18),
        axis.text.y = element_text(size = 18)
  )

# the plot I used # 

sent_prop <- sent_prop %>% 
  mutate_at(vars(1:2), factor)
ggplot(sent_prop, aes(x = treatment, y =  prop))+
  geom_point(aes(size = 5, color = treatment))+
  facet_wrap(~factor(growth_stage, level = c("V3", "V5", "R3")))+
  geom_errorbar(aes(x = treatment,ymin = prop - se, ymax = prop + se),
                color = "black", alpha = 1, width = 0.2, linewidth = 1)+
  scale_x_discrete(labels=c("No CC", "14-21 DPP", "3-7 DPP", "1-3 DAP"),
                   limits = c("1", "2", "4", "3"))+ 
  scale_color_manual(values = c("#E7298A", "#D95F02", "#1B9E77", "#7570B3"))+
  labs(
    title = "Soybean: Mean predation",
    subtitle = "Years: 2022-2023",
    x = "Treatment",
    y = "Mean proportion predated (x/1)"
  )+
  theme(legend.position = 'none',
        axis.title = element_text(size = 20),
        plot.subtitle = element_text(size = 18),
        plot.title = element_text(size = 24),
        # axis.line = element_line(size = 1.25),
        # axis.ticks = element_line(size = 1.25),
        # axis.ticks.length = unit(.25, "cm"),
        axis.text.x = element_text(size = 18),
        axis.text.y = element_text(size = 18),
        strip.text.x = element_text(size = 20), 
        panel.grid.major.y = element_line(color = "darkgrey"),
        panel.grid.major.x = element_blank(),
        panel.grid.minor = element_blank())
  




# nest for growth stage ####
# sent_22
# unique(sent_22$growth_stage)
# sent_23
# 
# nest_22 <- sent_22 %>% 
#   group_by(growth_stage) %>% 
#   nest()
# 
# gs_model <- function(gs_data){
#   glmer(to.predated ~ as.factor(treatment) +
#         (1|year/block/plot_id), 
#       data = gs_data, 
#       family = binomial)
# }
# 
# em_fxn <- function(sent_model){
#   emmeans(sent_model, pairwise ~ as.factor(treatment), type = "response")
# }
# 
# sent_22_gs <- nest_22 %>% 
#   mutate(models = map(data, gs_model),
#          emmeans_comb = map(models, em_fxn),
#          emmeans = map(.x = emmeans_comb, ~.x$emmeans))


# models that did not fit ####
#not a good fit 
block_md <- glmer(to.predated ~ as.factor(treatment) +
                (1|year/block), data = sent_years,
              family = binomial)
check_model(block_md)
summary(block_md)
r2_nakagawa(block_md)
result_block <- binned_residuals(block_md)
plot(result_block)

#singular fit
plot_md <- glmer(to.predated ~ as.factor(treatment) +
                   (1|year/block/plot_id) , data = sent_years, 
                 family = binomial)
check_model(plot_md)
summary(plot_md)
this <- binned_residuals(plot_md)
plot(this)
r2_nakagawa(plot_md)


growth_md <-  glmer(to.predated ~ as.factor(treatment)*growth_stage +
                      (1|year/block/plot_id) , data = sent_years, 
                    family = binomial)
check_model(growth_md)
summary(growth_md)
that <- binned_residuals(growth_md)
plot(that)
r2_nakagawa(growth_md)
