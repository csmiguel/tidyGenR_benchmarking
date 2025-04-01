###.............................................................................
# (c) Miguel Camacho Sánchez
# miguelcamachosanchez@gmail.com
# May 2024
###.............................................................................
#GOAL: fit reads after loci, variants,samples
#DESCRIPTION:
#PROJECT: tidyGenR_benchmarking
###.............................................................................
library(lme4)
library(tidyverse)

vdigest <- Vectorize(digest::digest)
vars <-
  readRDS("output/variants_x.rds")$ind_bs0 %>%
  mutate(variant = vdigest(sequence, "md5") %>%
           str_sub(1, 6) %>% as.factor(),
         locus = as.factor(locus)) %>%
  filter(locus != "fetub") %>%
  select(locus, sample, variant, reads) %>%
  arrange(locus, variant) %>%
  mutate(variant = factor(variant, levels = unique(variant[order(locus, variant)])))

# model reads, family poisson because it is counts
m1 <-
  glmer(reads ~ locus/variant + (1 | sample),
        data = vars, family = "poisson")
m0 <- glmer(reads ~ 1 + (1 | sample),
            data = vars, family = "poisson")
## predict data
# new data
loc_var <-
  vars %>% select(sample, locus, variant) %>% distinct()

pred <-
  lme4:::predict.merMod(m1, newdata = loc_var, se.fit = TRUE, re.form = ~ (1 | sample))

# reformat data for plot
df_plot <-
  cbind(loc_var, pred) %>%
  mutate(label_loc = paste(locus, variant, sep = "_"),
         color_points = as.numeric(locus) %% 2) %>%
  as_tibble()

# Plot the efficiencies as a box plot
# Plot the fixed effects estimates
p1 <-
  ggplot(df_plot, aes(x = label_loc, y = exp(fit), color = color_points)) +
  geom_point(stat = "identity") +
  labs(title = m1@call,
       x = "Variant",
       y = "Fit reads") +
  scale_y_continuous(transform = "log2",
                     breaks = c(20, 50, 100, 200, 500, 2000, 8000)) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 70, hjust = 1),
        legend.position = "none",
        plot.title = element_text(size = 6, face = "italic"))

# save fit results
l1 <- list(m1 = m1, m0 = m0, p1 = p1)

save(l1, file = "output/fit_reads.RData")
