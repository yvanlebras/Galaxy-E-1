library(data.table)

ValidHier=function(x,y) #used to write validator id over observer id
{
  if(y==""){x}else{y}
}

f2p <- function(x) #get date-time data from recording file names
{
  if (is.data.frame((x)[1])) {pretemps <- vector(length = nrow(x))}
  op <- options(digits.secs = 3)
  pretemps <- paste(substr(x, nchar(x) - 18, nchar(x)-4), ".", substr(x, nchar(x) - 2, nchar(x)), sep = "")
  strptime(pretemps, "%Y%m%d_%H%M%OS",tz="UTC")-7200
}



#Unique input file
args <- commandArgs(trailingOnly = TRUE)
#print(args)


#for test
#inputest=list.files("/media/linux-65mo/Linux/65MO/Galaxy-E/tools/Vigie-Chiro/test-data/output_idcorrect2ndlayer",full.names=T)
#for (i in 1:length(inputest))
#{
#args=c(inputest[i])
#print(inputest[i])


IdCorrect=fread(args[1])
#IdV=as.data.frame(subset(IdCorrect,select=observateur_taxon:validateur_probabilite))
#print(i) #Test for loop
#Step 0 :compute id score from 2nd Layer
test=match("participation",names(IdCorrect))
IdCorrect$IdProb=apply(as.data.frame(IdCorrect)[,(test+1):(ncol(IdCorrect)-1)],MARGIN=1,FUN=max)

#Step 1 :compute id with confidence regarding a hierarchy (validator > observer)
IdCorrect$IdV=mapply(ValidHier,IdCorrect$observateur_taxon,IdCorrect$validateur_taxon)
IdCorrect$ConfV=mapply(ValidHier,IdCorrect$observateur_probabilite
                       ,IdCorrect$validateur_probabilite)




#Step 2: Get numerictime data
#Little trick to supress warning
invisible(tryCatch({IdCorrect$Session=NULL}, warning=function(w){}))
invisible(tryCatch({IdCorrect$TimeNum=NULL}, warning=function(w){}))

if (substr(IdCorrect$`nom du fichier`[1],2,2)=="i") #for car/walk transects
{
  FileInfo=as.data.table(tstrsplit(IdCorrect$`nom du fichier`,"-"))
  IdCorrect$Session=as.numeric(substr(FileInfo$V4,5,nchar(FileInfo$V4)))
  TimeSec=as.data.table(tstrsplit(FileInfo$V5,"_"))
  TimeSec=as.data.frame(TimeSec)
  if(sum(TimeSec[,(ncol(TimeSec)-1)]!="00000")==0) #to deal with double Kaleidoscope treatments
  {
    print("NOMS DE FICHIERS NON CONFORMES")
    print("Vous les avez probablement traiter 2 fois par Kaleidoscope")
    stop("Merci de nous signaler cette erreur par mail pour correction")
      }else{
        IdCorrect$TimeNum=(IdCorrect$Session*800
        +as.numeric(TimeSec[,(ncol(TimeSec)-1)])
        +as.numeric(TimeSec[,(ncol(TimeSec))]))
  }
  
}else{
  if(substr(IdCorrect$`nom du fichier`[1],2,2)=="a") #for stationary recordings
  {
    DateRec=as.POSIXlt(f2p(IdCorrect$`nom du fichier`))
    Nuit=format(as.Date(DateRec-43200*(DateRec$hour<12)),format="%d/%m/%Y")
    #Nuit[is.na(Nuit)]=0
    IdCorrect$Session=Nuit
    IdCorrect$TimeNum=as.numeric(DateRec)
    
    }else{
      print("NOMS DE FICHIERS NON CONFORMES")
       stop("Ils doivent commencer par Cir (routier/pedestre) ou par Car (points fixes")
    }
}




#Step 3 :treat sequentially each species identified by Tadarida-C
IdExtrap=vector() #to store the id extrapolated from validations
IdC2=IdCorrect[0,] #to store data in the right order
TypeE=vector() #to store the type of extrapolation made
for (j in 1:nlevels(as.factor(IdCorrect$ProbEsp_C2bs)))
{
  IdSp=subset(IdCorrect
              ,IdCorrect$ProbEsp_C2bs==levels(as.factor(IdCorrect$ProbEsp_C2bs))[j])
  if(sum(IdSp$IdV=="")==(nrow(IdSp))) #case 1 : no validation no change
  {
    IdC2=rbind(IdC2,IdSp)
    IdExtrap=c(IdExtrap,rep(IdSp$ProbEsp_C2bs[1],nrow(IdSp)))
    TypeE=c(TypeE,rep(0,nrow(IdSp)))
  }else{ #case 2: some validation
    Vtemp=subset(IdSp,IdSp$IdV!="")
      #case2A: validations are homogeneous
    if(nlevels(as.factor(Vtemp$IdV))==1)
    {
      IdC2=rbind(IdC2,IdSp)
      IdExtrap=c(IdExtrap,rep(Vtemp$IdV[1],nrow(IdSp)))
      TypeE=c(TypeE,rep(2,nrow(IdSp)))
    }else{
      #case 2B: validations are heterogeneous
      #case 2B1: some validations confirms the species identified by Tadarida and highest confidence are confirmed
      subVT=subset(Vtemp,Vtemp$IdV==levels(as.factor(IdCorrect$ProbEsp_C2bs))[j])
      subVF=subset(Vtemp,Vtemp$IdV!=levels(as.factor(IdCorrect$ProbEsp_C2bs))[j])
      if((nrow(subVT)>0)&(max(subVT$IdProb)>max(subVF$IdProb)))
      {
        Vtemp=Vtemp[order(Vtemp$IdProb),]
        test=(Vtemp$IdV!=Vtemp$ProbEsp_C2bs)
        Fr1=max(which(test == TRUE)) #find the error with highest indices
        Thr1=mean(Vtemp$IdProb[(Fr1):(Fr1+1)]) #define first threshold as the median confidence between the first error and the confirmed ID right over it
        #id over this threshold are considered right
        IdHC=subset(IdSp,IdSp$IdProb>Thr1)
        IdC2=rbind(IdC2,IdHC)
        IdExtrap=c(IdExtrap,rep(Vtemp$IdV[nrow(Vtemp)],nrow(IdHC)))
        TypeE=c(TypeE,rep(2,nrow(IdHC)))
        #id under this threshold are attributed to validated id closest in time
        Vtemp=Vtemp[order(Vtemp$TimeNum),]
        cuts <- c(-Inf, Vtemp$TimeNum[-1]-diff(Vtemp$TimeNum)/2, Inf)
        CorrV=findInterval(IdSp$TimeNum, cuts)
        IdE=Vtemp$IdV[CorrV]
        IdEL=subset(IdE,IdSp$IdProb<=Thr1)
        IdLC=subset(IdSp,IdSp$IdProb<=Thr1)
        IdExtrap=c(IdExtrap,IdEL)
        TypeE=c(TypeE,rep(1,length(IdEL)))
        IdC2=rbind(IdC2,IdLC)
        
            
        }else{
          #case 2B2: all validations concerns errors
          #id are extrapolated on time only
          Vtemp=Vtemp[order(Vtemp$TimeNum),]
          cuts <- c(-Inf, Vtemp$TimeNum[-1]-diff(Vtemp$TimeNum)/2, Inf)
          CorrV=findInterval(IdSp$TimeNum, cuts)
          IdE=Vtemp$IdV[CorrV]
          IdExtrap=c(IdExtrap,IdE)
          TypeE=c(TypeE,rep(1,length(IdE)))
          IdC2=rbind(IdC2,IdSp)
          }
      }
    
    
   }
  
  
}
test1=(nrow(IdC2)==length(IdExtrap))
test2=(nrow(IdC2)==nrow(IdCorrect))
if((test1==F)|(test2==F))
{
  (stop("Erreur de traitement !!!"))
}

IdC2$IdExtrap=IdExtrap
IdC2$TypeE=TypeE

#Ordering for comparison
IdC2=IdC2[order(IdC2$tadarida_probabilite,decreasing=T),]
IdC2=IdC2[order(IdC2$`nom du fichier`),]

fout_name="output.tabular"
write.table(IdC2,fout_name,row.names=F,sep="\t")
#}#If for files in repo (test)
