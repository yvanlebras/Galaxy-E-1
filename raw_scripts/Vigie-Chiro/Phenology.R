"NbContactsHrSp=dcast(DataPar2,Heure~tadarida_taxon)\n",
"ConfContactsHrSp=dcast(DataPar2,Heure~tadarida_taxon,fun.aggregate=mean\n",
",value.var=\"probabilite\")\n",
Heure=substr(DataPar$'nom du fichier',nchar(DataPar$'nom du fichier')-9,nchar(DataPar$'nom du fichier')-8)\n",
"DataPar2=cbind(DataPar,Heure)\n",
"NbContactsHrSp=dcast(DataPar2,Heure~tadarida_taxon)\n",
"ConfContactsHrSp=dcast(DataPar2,Heure~tadarida_taxon,fun.aggregate=mean\n",
",value.var=\"probabilite\")\n",
                        "ConfContactsHrSp[is.na(ConfContactsHrSp)]=0\n",
                        "NBCHSdebut=subset(NbContactsHrSp,substr(NbContactsHrSp$Heure,1,1)!=\"0\")\n",
                        "NBCHSfin=subset(NbContactsHrSp,substr(NbContactsHrSp$Heure,1,1)==\"0\")\n",
                        "NBCHS2=as.data.frame(rbind(NBCHSdebut,NBCHSfin))\n",
                        "CCHSdebut=subset(ConfContactsHrSp,substr(ConfContactsHrSp$Heure,1,1)!=\"0\")\n",
                        "CCHSfin=subset(ConfContactsHrSp,substr(ConfContactsHrSp$Heure,1,1)==\"0\")\n",
                        "CCHS2=as.data.frame(rbind(CCHSdebut,CCHSfin))
"breaks <- c(-Inf, 0.50, 0.75, Inf)\n",
"\n",
"for (i in 2:ncol(NBCHS2))\n",
"{\n",
"  cols=c(\"yellow\",\"palegreen\", \"limegreen\")[findInterval(CCHS2[,i], vec=breaks)]\n",
           "  barplot(NBCHS2[,i],names.arg=NBCHS2$Heure,main=colnames(NBCHS2)[i],col=cols)\n",
           "}\n"
           