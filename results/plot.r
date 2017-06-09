library(ggplot2)
library(scales)
args = commandArgs(trailingOnly=TRUE)

data_usage_path = args[1]
vm_usage_path = args[2]
running_usage_path = args[3]

#site usage timestamp
data_usage = read.table(sep = " ", data_usage_path, header = T)
vm_usage = read.table(sep = " ", vm_usage_path, header = T)
running_usage = read.table(sep = " ", running_usage_path, header = T)

data_usage$usage = as.numeric(sub("%", "", data_usage$usage))

data_usage$timestamp = data_usage$timestamp - 10800
vm_usage$timestamp = vm_usage$timestamp - 10800
running_usage$timestamp = running_usage$timestamp + 10800

#dataset = rbind(data_usage, vm_usage, running_usage)
dataset = rbind(data_usage, running_usage)
dataset = subset(dataset, dataset$site %in% c("manager.naf.ufscar.br","experimento.manager.naf.lsd.ufcg.edu.br"))

min_stamp = min(dataset$timestamp)
dataset$rel_timestamp = dataset$timestamp - min_stamp

dataset$datetime <- as.POSIXct(dataset$timestamp, origin="1970-01-01", tz="GMT")

summary(dataset)

# plot baseado em data
p = ggplot(data=dataset, aes(x=datetime, y=usage, color=type)) + geom_line(size=1.1) + scale_x_datetime(labels = date_format("%d-%m %H:%M"), breaks=date_breaks("8 hour")) + theme(axis.text.x = element_text(angle = 45, hjust = 1))
p = p + facet_grid(site ~ .)
ggsave("saps_date.png", p)

#plot baseado em timestamp
p = ggplot(data=dataset, aes(x=timestamp, y=usage, color=type)) + geom_line(size=1.1) + xlab("duração (h)")
p = p + facet_grid(site ~ .)
ggsave("saps_timestamp.png", p)

#plot baseado em horas relativas desde o inicio do experimento
p = ggplot(data=dataset, aes(x=rel_timestamp/3600, y=usage, color=type)) + geom_line(size=1.1) + xlab("duração (h)")
p = p + facet_grid(site ~ .)
ggsave("saps_rel_timestamp_1.png", p)

#plot baseado em horas relativas desde o inicio do experimento (truncado em 30h)
dataset = subset(dataset, dataset$rel_timestamp < (3600*30))
p = ggplot(data=dataset, aes(x=rel_timestamp/3600, y=usage, color=type)) + geom_line(size=1.1) + xlab("duração (h)")
p = p + facet_grid(site ~ .)
ggsave("saps_rel_timestamp_2.png", p)
