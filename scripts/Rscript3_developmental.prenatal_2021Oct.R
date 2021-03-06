###Version 1. TPM >= 1 in at least one stage instead of two stage are used.
###Version 2. Ranks of expression among genome is analyzed.

library(dplyr);library(reshape2)
library(ggplot2);library(ggsignif)
library(gridExtra)


all.pair <- read.csv("../datafiles/all.pair.gi.csv", header=T, row.names=1, stringsAsFactors = F)
all.pair <- all.pair %>% mutate(robust = ifelse(robust == "Robust", "Robust", "Conditional"))
all.pair <- all.pair %>% mutate(robust = ifelse(Y > 0, robust, "Others"))
all.pair$robust <- factor(all.pair$robust, levels=c("Robust", "Conditional", "Others"))

all.pair.genes <- all.pair %>% select(pair, gene1, gene2) %>% melt(id.vars=c("pair")) %>% rename(genename = value, pairID = variable)


###Part 1. The median correlation of random pairs
development <- readRDS("../datafiles/development.scaled.TPM.week.rds")

expression.cor.random <- function(tissue){
all.pair.exp <- development[[tissue]] %>% filter(genename %in% all.pair.genes$genename)
all.pair.exp <- all.pair.exp[, grep( "week[0-9]", names(all.pair.exp), perl=T, inver=T )]
row.names(all.pair.exp) <- all.pair.exp$genename

all.pair.cor <- all.pair.exp[rowSums(all.pair.exp[,-(1:2)] >= 1) >= 1, -(1:2)] %>% t() %>% cor() %>% melt()

return( median(all.pair.cor$value) )
}

all.pair.cor.tissues.random <- data.frame()
for(s in names(development)){
all.pair.cor.tissues.random <- rbind.data.frame( all.pair.cor.tissues.random, data.frame("tissue" = s, "correlation" = expression.cor.random(s), "robust" = "random" ) )
}
all.pair.cor.tissues.random.prenatal <- all.pair.cor.tissues.random
all.pair.cor.tissues.random.prenatal$tissue <- as.character( all.pair.cor.tissues.random.prenatal$tissue )


development <- readRDS("../datafiles/development.scaled.TPM.week.rds")
development[["ovary"]]  <- NULL
development[["kidney"]] <- NULL

expression.cor.random <- function(tissue){
all.pair.exp <- development[[tissue]] %>% filter(genename %in% all.pair.genes$genename)
all.pair.exp <- all.pair.exp[, grep( "week-", names(all.pair.exp), perl=T, inver=T )]
row.names(all.pair.exp) <- all.pair.exp$genename

all.pair.cor <- all.pair.exp[rowSums(all.pair.exp[,-(1:2)] >= 1) >= 1, -(1:2)] %>% t() %>% cor() %>% melt()

return( median(all.pair.cor$value) )
}

all.pair.cor.tissues.random <- data.frame()
for(s in names(development)){
all.pair.cor.tissues.random <- rbind.data.frame( all.pair.cor.tissues.random, data.frame("tissue" = s, "correlation" = expression.cor.random(s), "robust" = "random" ) )
}
all.pair.cor.tissues.random.postnatal <- all.pair.cor.tissues.random
all.pair.cor.tissues.random.postnatal$tissue <- as.character( all.pair.cor.tissues.random.postnatal$tissue )



###Part 2. The median correlation of duplicate pairs. Pre-natal
development <- readRDS("../datafiles/development.scaled.TPM.week.rds")

expression.cor <- function(tissue){
all.pair.exp <- development[[tissue]] %>% filter(genename %in% all.pair.genes$genename)
all.pair.exp <- all.pair.exp[, grep( "week[0-9]", names(all.pair.exp), perl=T, inver=T )]
row.names(all.pair.exp) <- all.pair.exp$genename

all.pair.cor <- all.pair.exp[rowSums(all.pair.exp[,-(1:2)] >= 1) >= 1, -(1:2)] %>% t() %>% cor() %>% melt()

all.pair.cor <- all.pair %>% select(pair, gene1, gene2, robust) %>% inner_join(all.pair.cor, by=c("gene1" = "Var1", "gene2" = "Var2")) %>% mutate("tissue" = tissue)

all.pair.exp <- all.pair.genes %>% mutate("tissue" = tissue) %>% inner_join(all.pair.exp[,-1], by=c("genename")) %>% melt(id.vars=c("pair", "pairID", "genename", "tissue" ))

return(list("correlation" = all.pair.cor, "expression" = all.pair.exp))
}

all.pair.cor.tissues <- data.frame()
all.pair.exp.tissues <- data.frame()
for(s in names(development)){
k <- expression.cor(s)

all.pair.cor.tissues <- rbind.data.frame( all.pair.cor.tissues, k[["correlation"]] )
all.pair.exp.tissues <- rbind.data.frame( all.pair.exp.tissues, k[["expression"]] )
}


all.pair.cor.tissues$robust <- factor( all.pair.cor.tissues$robust, levels=c("Robust", "Conditional", "Others") )

all.pair.cor.tissues.prenatal <- all.pair.cor.tissues

m1 <- aggregate(all.pair.cor.tissues.prenatal$value, by=list(all.pair.cor.tissues.prenatal$tissue, all.pair.cor.tissues.prenatal$robust), median) %>% arrange(Group.1, Group.2) %>% rename(tissue=Group.1, robust=Group.2, correlation=x)
p1 <- rbind.data.frame(m1, all.pair.cor.tissues.random.prenatal %>% select(tissue, correlation, robust) %>% arrange(tissue) ) %>% ggplot(aes(x=tissue, y=correlation, col=robust)) + geom_path(aes(group=robust)) +geom_point() + theme_bw() + theme(axis.title=element_text(size=20, face="bold"), axis.text.x=element_text(size=17), axis.text.y=element_text(size=17), legend.title=element_text(size=18, face="bold"), legend.text=element_text(size=17), strip.background = element_rect(fill = NA), strip.text=element_text(size=18), plot.tag=element_text(size=28, face="bold")) + xlab("Tissues") + ylab("Median co-expression correlation") + scale_color_manual(values=c("#7372B7", "#F2CA66", "#3BA6D9", "Salmon3"), guide = guide_legend( title = "Negative GI type" ), labels=c("Core", "Conditional", "Others", "Random pairs" ))



###Part 3. The median correlation of duplicate pairs. Post-natal
development <- readRDS("../datafiles/development.scaled.TPM.week.rds")
development[["ovary"]]  <- NULL  ###They do not have enough postnatal data.
development[["kidney"]] <- NULL  ###They do not have enough postnatal data.

expression.cor <- function(tissue){
all.pair.exp <- development[[tissue]] %>% filter(genename %in% all.pair.genes$genename)
all.pair.exp <- all.pair.exp[, grep( "week-", names(all.pair.exp), perl=T, inver=T )]
row.names(all.pair.exp) <- all.pair.exp$genename

all.pair.cor <- all.pair.exp[rowSums(all.pair.exp[,-(1:2)] >= 1) >= 1, -(1:2)] %>% t() %>% cor() %>% melt()

all.pair.cor <- all.pair %>% select(pair, gene1, gene2, robust) %>% inner_join(all.pair.cor, by=c("gene1" = "Var1", "gene2" = "Var2")) %>% mutate("tissue" = tissue)

all.pair.exp <- all.pair.genes %>% mutate("tissue" = tissue) %>% inner_join(all.pair.exp[,-1], by=c("genename")) %>% melt(id.vars=c("pair", "pairID", "genename", "tissue" ))

return(list("correlation" = all.pair.cor, "expression" = all.pair.exp))
}

all.pair.cor.tissues <- data.frame()
all.pair.exp.tissues <- data.frame()
for(s in names(development)){
k <- expression.cor(s)

all.pair.cor.tissues <- rbind.data.frame( all.pair.cor.tissues, k[["correlation"]] )
all.pair.exp.tissues <- rbind.data.frame( all.pair.exp.tissues, k[["expression"]] )
}


all.pair.cor.tissues <- all.pair.cor.tissues
all.pair.cor.tissues$robust <- factor( all.pair.cor.tissues$robust, levels=c("Robust", "Conditional", "Others") )

all.pair.cor.tissues.postnatal <-  all.pair.cor.tissues

m2 <- aggregate(all.pair.cor.tissues.postnatal$value, by=list(all.pair.cor.tissues.postnatal$tissue, all.pair.cor.tissues.postnatal$robust), median) %>% arrange(Group.1, Group.2) %>% rename(tissue=Group.1, robust=Group.2, correlation=x)
p2 <- rbind.data.frame(m2, all.pair.cor.tissues.random.postnatal %>% select(tissue, correlation, robust) %>% arrange(tissue) ) %>% ggplot(aes(x=tissue, y=correlation, col=robust)) + geom_path(aes(group=robust)) +geom_point() + theme_bw() + theme(axis.title=element_text(size=20, face="bold"), axis.text.x=element_text(size=17), axis.text.y=element_text(size=17), legend.title=element_text(size=18, face="bold"), legend.text=element_text(size=17), strip.background = element_rect(fill = NA), strip.text=element_text(size=18), plot.tag=element_text(size=28, face="bold")) + xlab("Tissues") + ylab("Median co-expression correlation") + scale_color_manual(values=c("#7372B7", "#F2CA66", "#3BA6D9", "Salmon3"), guide = guide_legend( title = "Negative GI type" ), labels=c("Core", "Conditional", "Others", "Random pairs" ))



###Part 4. A combined plot of prenatal and postnatal stages.
s1 <- aggregate(all.pair.cor.tissues.prenatal$value,  by=list(all.pair.cor.tissues.prenatal$tissue, all.pair.cor.tissues.prenatal$robust), median) %>% arrange(Group.1, Group.2) %>% rename(tissue=Group.1, robust=Group.2, correlation=x) %>% mutate(stage = "pre")
s2 <- aggregate(all.pair.cor.tissues.postnatal$value, by=list(all.pair.cor.tissues.postnatal$tissue, all.pair.cor.tissues.postnatal$robust), median) %>% arrange(Group.1, Group.2) %>% rename(tissue=Group.1, robust=Group.2, correlation=x) %>% mutate(stage = "post")

s3 <- rbind.data.frame(s1, s2)
s3 <- s3[,1:2][duplicated(s3[,1:2]), ] %>% inner_join(s3, by=c("tissue", "robust"))
s3$stage <- factor(s3$stage, levels=c("pre", "post"))

p3 <- s3 %>% rename(Tissues = tissue) %>% ggplot(aes(x=stage, y=correlation, group=Tissues, shape=Tissues)) + geom_point(size=3) + geom_line(lty="dashed") + facet_wrap(~robust, nrow=1) + theme_bw() + theme(axis.title=element_text(size=20, face="bold"), axis.text.x=element_text(size=17), axis.text.y=element_text(size=17), legend.title=element_text(size=18, face="bold"), legend.text=element_text(size=17), strip.background = element_rect(fill = NA), strip.text=element_text(size=17), plot.tag=element_text(size=28, face="bold")) + xlab("Prenatal or postnatal development") + ylab("Median co-expression level")


s4 <- rbind.data.frame( rbind.data.frame(m1, all.pair.cor.tissues.random.prenatal %>% select(tissue, correlation, robust) %>% arrange(tissue) ) %>% mutate( development = "Prenatal" ), rbind.data.frame(m2, all.pair.cor.tissues.random.postnatal %>% select(tissue, correlation, robust) %>% arrange(tissue) ) %>% mutate( development = "Postnatal" ) )
s4$development <- factor(s4$development, levels=c("Prenatal", "Postnatal"))

p4 <- s4 %>% ggplot(aes(x=tissue, y=correlation, col=robust)) + geom_path(aes(group=robust)) +geom_point() + theme_bw() + theme(axis.title=element_text(size=20, face="bold"), axis.text.x=element_text(size=17), axis.text.y=element_text(size=17), legend.title=element_text(size=18, face="bold"), legend.text=element_text(size=17), strip.background = element_rect(fill = NA), strip.text=element_text(size=20), plot.tag=element_text(size=28, face="bold")) + xlab("Tissues") + ylab("Median co-expression level") + scale_color_manual(values=c("#7372B7", "#F2CA66", "#3BA6D9", "Salmon3"), guide = guide_legend( title = "Pair type" ), labels=c("Core negative GI (Duplicate pair)", "Conditional negative GI (Duplicate pair)", "Non-nGI (Duplicate pair)", "Random pairs" )) + facet_grid(~development, scale="free_x")


###Cases of correlation. Draw trends in development.
development <- readRDS("../datafiles/development.scaled.TPM.week.rds")

stage <- read.table( "../datafiles/stage.time", header = T)
for(i in 1:(dim(stage)[2])){ stage[,i] <- as.character( stage[,i] ) }
stage <- stage %>% select(ID, Week) %>% unique
stage$ID <- sub("w$", " PCW", stage$ID )
stage$ID <- sub("dpb$", " DPB", stage$ID )
stage$ID <- sub("ypb$", " YPB", stage$ID )

plot_trace <- function( Tissue, gene_1, gene_2, ypos ){
t1 <- development[[Tissue]] %>% filter(genename %in% c(gene_1, gene_2) ) %>% melt(id.vars=c("geneID", "genename")) %>% rename(Genename = genename, Week = variable, TPM = value )
t1$Week <- sub("week", "", t1$Week)

t1 <- t1 %>% inner_join( stage, by=c("Week"))
t1$ID <- factor(t1$ID, levels=unique(t1$ID))

s  <- t1[grep("-", t1$Week),] %>% select(Genename, Week, TPM) %>% dcast(Week~Genename, value.var = "TPM") %>% mutate(Week = NULL)
c1 <- cor(s[,1], s[,2]) %>% format( digits = 2 )
d1 <- ( cor.test(s[,1], s[,2]) )$p.value %>% format( digits = 2 )

s  <- t1[grep("-", t1$Week, invert=T),] %>% select(Genename, Week, TPM) %>% dcast(Week~Genename, value.var = "TPM") %>% mutate(Week = NULL)
c2 <- cor(s[,1], s[,2]) %>% format( digits = 2 )
d2 <- ( cor.test(s[,1], s[,2]) )$p.value %>% format( digits = 2 )

p0 <- t1 %>% rename(Symbol = Genename) %>% ggplot(aes(x=ID, y=TPM, col=Symbol, group=Symbol)) + geom_point() + geom_path() + theme_bw() + theme(axis.title=element_text(size=20, face="bold"), axis.text.x=element_text(size=17, angle=15), axis.text.y=element_text(size=17), legend.title=element_text(size=18, face="bold"), legend.text=element_text(size=17), strip.background = element_rect(fill = NA), strip.text=element_text(size=18), plot.tag=element_text(size=28, face="bold"), legend.position="top") + xlab(paste("Developmental time of ", Tissue, sep='') ) + ylab("Expression level (TPM)") + annotate(geom = 'text', label = paste("R = ", c1, "\n", "P = ", d1, sep=''), x = 12, y = ypos, size=5.8) + annotate(geom = 'text', label = paste(" R = ", c2, "\n", "P = ", d2, sep=''), x = 16, y = ypos, size=5.8)

return(p0)
}

 

###Part 5. rank of co-expression among genome
#development <- readRDS("../datafiles/development.scaled.TPM.week.rds")

#rank.genes  <- all.pair.genes %>% select(genename) %>% unlist() %>% as.character() %>% unique()

#genome_cor_tissue <- function( tissue = "kidney", genes = rank.genes ){

#s <- development[[tissue]] 
#s <- s[, grep( "week[0-9]", names(s), perl=T, inver=T )]  ###pre-natal
#s <- s[, grep( "week-", names(s), perl=T, inver=T )]  ###post-natal
#row.names(s) <- s$genename
#t <- s[rowSums(s[,-(1:2)] >= 1) >= 1, -(1:2)] %>% t() %>% cor() 
#t_top <- nrow(t)/20

#genome_cor  <- function(gene){
#t1 <- t[gene,] %>% as.data.frame()
#names(t1)[1] <- "correlation"
#t1$gene1 <- gene
#t1$gene2 <- row.names(t1)
#t1 <- t1 %>% filter( correlation > 0.2 ) %>% arrange( desc(correlation) )
#t1 <- t1[1:t_top, ]
#t1$rank <- 1:nrow(t1)
#return( t1 )
#}

#genes <- genes[genes %in% row.names(t)]
#genome_cor_all <- data.frame()
#for( i in genes ){
#genome_cor_all <- rbind.data.frame(genome_cor_all, genome_cor( i ) )
#}

#return(genome_cor_all %>% mutate("tissue" = tissue))
#}

#genome_cor_rank <- data.frame()
#for(tissue in names(development) ){
#print(paste(date(), ";", tissue, "has started.", sep=' '))
#genome_cor_rank.tissue <- genome_cor_tissue( tissue = tissue, genes = rank.genes )

#genome_cor_rank <- rbind.data.frame( genome_cor_rank, genome_cor_rank.tissue )
#print(paste(date(), ";", tissue, "has finished.", sep=' '))
#}

#t1 <- genome_cor_rank %>% inner_join(all.pair %>% select(gene1, gene2, pair, robust), by=c("gene1" = "gene1", "gene2" = "gene2") )
#t2 <- genome_cor_rank %>% inner_join(all.pair %>% select(gene1, gene2, pair, robust), by=c("gene1" = "gene2", "gene2" = "gene1") )
#t3 <- rbind.data.frame(t1, t2)
#saveRDS( t3, "genome_cor_rank.prenatal.rds" )
#saveRDS( t3, "genome_cor_rank.postnatal.rds" )


###Random combination of a pair. Proportion of significant correlation.
#t3.random.prenatal <- genome_cor_rank %>% filter(gene1 %in% all.pair.genes$genename) %>% filter(gene2 %in% all.pair.genes$genename)
#saveRDS( t3.random.prenatal, "genome_cor_rank.prenatal.random.rds" )
#t3.random.postnatal <- genome_cor_rank %>% filter(gene1 %in% all.pair.genes$genename) %>% filter(gene2 %in% all.pair.genes$genename)
#saveRDS( t3.random.postnatal, "genome_cor_rank.postnatal.random.rds" )



###Part 6. Significant correlated pairs. Random pairs
t3.random.prenatal <- readRDS( "../datafiles/genome_cor_rank.prenatal.random.rds" )
t3.random.prenatal$gene1 <- factor( t3.random.prenatal$gene1, levels= unique(all.pair.genes$genename) )
t3.random.prenatal$gene2 <- factor( t3.random.prenatal$gene2, levels= unique(all.pair.genes$genename) )
t3.random.prenatal.correlated <- t3.random.prenatal %>% filter(gene1 != gene2) %>% inner_join( t3.random.prenatal %>% select(gene1, gene2, rank, tissue), by=c("gene1"="gene2", "gene2"="gene1", "tissue"="tissue") )
k.random.prenatal.correlated  <- t3.random.prenatal.correlated %>% select(gene1, gene2) %>% unique() %>% nrow()
k.random.prenatal.correlated  <- k.random.prenatal.correlated/2   ###A-B and B-A pair is counted twice.
c0.prenatal <- k.random.prenatal.correlated/choose(length( unique(t3.random.prenatal$gene1) ), 2)

t3.random.postnatal <- readRDS( "../datafiles/genome_cor_rank.postnatal.random.rds" )
t3.random.postnatal$gene1 <- factor( t3.random.postnatal$gene1, levels= unique(all.pair.genes$genename) )
t3.random.postnatal$gene2 <- factor( t3.random.postnatal$gene2, levels= unique(all.pair.genes$genename) )
t3.random.postnatal.correlated <- t3.random.postnatal %>% filter(gene1 != gene2) %>% inner_join( t3.random.postnatal %>% select(gene1, gene2, rank, tissue), by=c("gene1"="gene2", "gene2"="gene1", "tissue"="tissue") )
k.random.postnatal.correlated  <- t3.random.postnatal.correlated %>% select(gene1, gene2) %>% unique() %>% nrow()
k.random.postnatal.correlated  <- k.random.postnatal.correlated/2   ###A-B and B-A pair is counted twice.
c0.postnatal <- k.random.postnatal.correlated/choose(length( unique(t3.random.postnatal$gene1) ), 2)


###Significant correlated pairs. Duplicate pairs
t3 <- readRDS("../datafiles/genome_cor_rank.prenatal.rds")
for(i in 1:dim(t3)[2]){t3[,i] <- as.character(t3[,i])}
t4 <- t3[duplicated(t3 %>% select(tissue, pair, robust)),]
all.pair.cor.rank.prenatal <- all.pair %>% select(pair, gene1, gene2, robust)  %>% mutate(cor = ifelse(pair %in% t4$pair, "Corr", "N.corr" ))

t3 <- readRDS("../datafiles/genome_cor_rank.postnatal.rds")
for(i in 1:dim(t3)[2]){t3[,i] <- as.character(t3[,i])}
t4 <- t3[duplicated(t3 %>% select(tissue, pair, robust)),]
all.pair.cor.rank.postnatal <- all.pair %>% select(pair, gene1, gene2, robust) %>% mutate(cor = ifelse(pair %in% t4$pair, "Corr", "N.corr" ))


all.pair.cor.rank.prenatal.ratio  <- all.pair.cor.rank.prenatal %>% select(robust, cor) %>% table() %>% as.data.frame() %>% dcast(robust~cor, value.var=c("Freq")) %>% mutate(Total = (Corr + N.corr) ) %>% mutate(Ratio = Corr/(Total)) %>% mutate(sd=sqrt(Ratio/(Total)))
all.pair.cor.rank.postnatal.ratio <- all.pair.cor.rank.postnatal %>% select(robust, cor) %>% table() %>% as.data.frame() %>% dcast(robust~cor, value.var=c("Freq")) %>% mutate(Total = (Corr + N.corr) ) %>% mutate(Ratio = Corr/(Total)) %>% mutate(sd=sqrt(Ratio/(Total)))

k1 <- (all.pair.cor.rank.prenatal.ratio %>% filter(robust %in% c("Robust", "Conditional") ) %>% select(Corr, N.corr) %>% fisher.test(alternative='greater'))$p.value %>% format(digits=2)
k2 <- (all.pair.cor.rank.prenatal.ratio %>% filter(robust %in% c("Robust", "Others") ) %>% select(Corr, N.corr) %>% fisher.test(alternative='greater'))$p.value %>% format(digits=2)
p.rate.prenatal  <- all.pair.cor.rank.prenatal.ratio %>% ggplot(aes(x=robust,  y=Ratio)) + geom_bar(aes(fill = robust), stat="identity") + geom_errorbar(aes(ymin=Ratio-sd, ymax=Ratio+sd), width=0.3) + scale_fill_manual(values=c("#7372B7", "#F2CA66", "#3BA6D9")) + theme_bw() + theme(title=element_text(size=20, face="bold"), axis.text=element_text(size=17), legend.text=element_text(size=17), plot.title=element_text(size=20, face="bold"), plot.tag=element_text(size=28, face="bold"), legend.position = "none" ) + xlab("Negative GI type") + ylab("Proportion of \nsigniﬁcantly co-expressed pairs") + geom_text(aes(x=robust, y=ypos, label=label), data=(all.pair.cor.rank.prenatal.ratio %>% mutate(ypos=0.90, label=paste(Corr, Total, sep="/"))), size=5.8) + geom_text(aes(x=x, y=y, label=label), data=data.frame(x=1.5, y=0.63, label=k1), size=5.8)+ geom_path(aes(x=x, y=y), data= data.frame("x"=c(1, 1, 2, 2), "y"=c(0.58, 0.60, 0.60, 0.58)), lwd=0.7) + geom_text(aes(x=x, y=y, label=label), data=data.frame(x=2.0, y=0.73, label=k2), size=5.8)+ geom_path(aes(x=x, y=y), data= data.frame("x"=c(1, 1, 3, 3), "y"=c(0.68, 0.70, 0.70, 0.68)), lwd=0.7) + geom_hline(yintercept = c0.prenatal, lty="dashed") +  scale_x_discrete(labels=c("Core", "Conditional", "Non-nGI"))
 

binom.test(46, 99, p = c0.prenatal)
binom.test(39, 111, p = c0.prenatal)
binom.test(609, 1958, p = c0.prenatal)

k1 <- (all.pair.cor.rank.postnatal.ratio %>% filter(robust %in% c("Robust", "Conditional") ) %>% select(Corr, N.corr) %>% fisher.test(alternative = 'greater'))$p.value %>% format(digits=2)
k2 <- (all.pair.cor.rank.postnatal.ratio %>% filter(robust %in% c("Robust", "Others") ) %>% select(Corr, N.corr) %>% fisher.test(alternative='greater'))$p.value %>% format(digits=2)
p.rate.postnatal <- all.pair.cor.rank.postnatal.ratio %>% ggplot(aes(x=robust,  y=Ratio)) + geom_bar(aes(fill = robust), stat="identity") + geom_errorbar(aes(ymin=Ratio-sd, ymax=Ratio+sd), width=0.3) + scale_fill_manual(values=c("#7372B7", "#F2CA66", "#3BA6D9")) + theme_bw() + theme(title=element_text(size=20, face="bold"), axis.text=element_text(size=17), legend.text=element_text(size=17), plot.title=element_text(size=20, face="bold"), plot.tag=element_text(size=28, face="bold"), legend.position = "none" ) + xlab("Negative GI type") + ylab("Proportion of \nsigniﬁcantly co-expressed pairs") + geom_text(aes(x=robust, y=ypos, label=label), data=(all.pair.cor.rank.postnatal.ratio %>% mutate(ypos=0.90, label=paste(Corr, Total, sep="/"))), size=5.8) + geom_text(aes(x=x, y=y, label=label), data=data.frame(x=1.5, y=0.63, label=k1), size=5.8)+ geom_path(aes(x=x, y=y), data= data.frame("x"=c(1, 1, 2, 2), "y"=c(0.58, 0.60, 0.60, 0.58)), lwd=0.7) + geom_text(aes(x=x, y=y, label=label), data=data.frame(x=2.0, y=0.73, label=k2), size=5.8)+ geom_path(aes(x=x, y=y), data= data.frame("x"=c(1, 1, 3, 3), "y"=c(0.68, 0.70, 0.70, 0.68)), lwd=0.7) + geom_hline(yintercept = c0.postnatal, lty="dashed") +  scale_x_discrete(labels=c("Core", "Conditional", "Non-nGI"))


binom.test(27, 99, p = c0.postnatal)
binom.test(36, 111, p = c0.postnatal)
binom.test(448, 1958, p = c0.postnatal)


###The number of significantly coregulated tissues. Breadth distribution. Only prenatal tissues are showed.
t3 <- readRDS("../datafiles/genome_cor_rank.prenatal.rds")
t4.prenatal <- t3[duplicated(t3 %>% select(tissue, pair, robust)),]
t5.prenatal <- t4.prenatal %>% select(pair,robust) %>% table() %>% as.data.frame() %>% filter(Freq > 0) %>% filter(robust == "Robust") %>% arrange( desc(Freq ))

t3 <- readRDS("../datafiles/genome_cor_rank.postnatal.rds")
t4.postnatal <- t3[duplicated(t3 %>% select(tissue, pair, robust)),]
t5.postnatal <- t4.postnatal %>% select(pair,robust) %>% table() %>% as.data.frame() %>% filter(Freq > 0) %>% filter(robust == "Robust") %>% arrange( desc(Freq ))

p.cor.tissue.prenatal <- t4.prenatal %>% select(pair,robust) %>% table() %>% as.data.frame() %>% filter(Freq > 0) %>% select(robust, Freq) %>% table() %>% as.data.frame() %>% rename(Cell=Freq, Freq=Freq.1) %>% filter(robust == "Robust") %>% ggplot() + geom_bar(aes(x=Cell, y=Freq), fill = "#7372B7", stat="identity") + theme_bw() + xlab("Number of co-expressed organs (prenatal)") + ylab("Number of duplicate pairs") + theme(axis.title=element_text(size=20, face="bold"), axis.text = element_text(size=17), legend.title=element_text(size=20, face="bold"), legend.text=element_text(size=18),  plot.tag=element_text(size=28, face="bold"), legend.position=c(0.8, 0.8) ) + geom_label(aes(x=Freq, y=Freq, label=pair), data = t5.prenatal %>% filter(Freq > 2), size=5.2)



pdf("../Figure4_Development.correlation.comparison_2021Oct.pdf", width=16, height=16)
grid.arrange( p3 + labs(tag="A"), p.cor.tissue.prenatal + labs(tag="C"), p.rate.prenatal + ggtitle("Prenatal") + labs(tag="B"), p.rate.postnatal + ggtitle("Postnatal") + labs(tag="B"), plot_trace("brain", "ROCK1", "ROCK2", 35) + theme(legend.position = "top", axis.text.x = element_text(angle = 30)) + labs(tag="D") + theme(legend.position = "top"),  layout_matrix = matrix(c(rep(1:4,rep(5,4)), rep(5,9), rep(6,1) ), nrow=3, byrow=T) )
dev.off()


pdf("../FigureS4_Development.correlation.comparison.supplementary4_2021Oct.pdf", width=15, height=5.5)
grid.arrange( p4, layout_matrix = matrix(1, nrow=1) )
dev.off()


###Save data
t4.prenatal.matrix <- t4.prenatal %>% mutate( sig = "significant") %>% dcast(pair+robust~tissue, value.var = "sig")
t4.prenatal.matrix <- all.pair.cor.tissues.prenatal %>% dcast(pair+gene1+gene2+robust~tissue, value.var = "value") %>% left_join( t4.prenatal.matrix, by=c("pair", "robust") )
t4.prenatal.matrix[,12:18][ is.na( t4.prenatal.matrix[,12:18] ) ] <- ""

t4.postnatal.matrix <- t4.postnatal %>% mutate( sig = "significant") %>% dcast(pair+robust~tissue, value.var = "sig")
t4.postnatal.matrix <- all.pair.cor.tissues.postnatal %>% dcast(pair+gene1+gene2+robust~tissue, value.var = "value") %>% left_join( t4.postnatal.matrix, by=c("pair", "robust") )
t4.postnatal.matrix[,10:14][ is.na( t4.postnatal.matrix[,10:14] ) ] <- ""

write.csv( all.pair %>% select( gene1, gene2, pair, robust) %>% left_join( t4.prenatal.matrix, by=c("gene1", "gene2", "pair", "robust") ) %>% left_join( t4.postnatal.matrix, by=c("gene1", "gene2", "pair", "robust") ), "../Tables8_all.pair.cor.tissues.significant.csv" )
