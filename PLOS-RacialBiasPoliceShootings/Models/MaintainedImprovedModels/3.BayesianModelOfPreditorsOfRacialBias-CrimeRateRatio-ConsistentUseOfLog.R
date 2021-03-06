################################# Load Data ####################################################################################
library(rstan)
library(rethinking)

g <- read.csv(file.choose())    # MapFileData-WithCountyResultsAndCovariates.csv
goog <- read.csv(file.choose()) # RacismData_Google-Stephens-Davidowitz.csv
 
############################################################### Extract Data
Ym <- g$m.log.RR_Black_Unarmed_Versus_White_Unarmed     # First Outcome
Ysd <- g$sd.log.RR_Black_Unarmed_Versus_White_Unarmed   #

############################################################### Define race-specific crime rates
WhiteAssault <- (g$AssaultsWhite.sum/g$WA_TOT)
BlackAssault <- (g$AssaultsBlack.sum/g$BAC_TOT)

WhiteWeapons <- (g$WeaponsWhite.sum/g$WA_TOT)
BlackWeapons <- (g$WeaponsBlack.sum/g$BAC_TOT)

############################################################## Extract other data
Wealth <- (g$Median.Income)

Pop <- g$TOT_POP

BlackRatio <- (g$BAC_TOT+1)/Pop # Add 1 person to population to scale off of zero

Gini <- g$Gini

State <- g$State

DMA <- g$DMA

################################################################### Compile Data
#### then reduce to only data with estimates of racial bias in police shooting
g2 <- data.frame(g$County.FIPS.Code,Ym,Ysd, Gini, Wealth,Pop,State,BlackRatio,Gini,DMA,WhiteAssault,BlackAssault,WhiteWeapons,BlackWeapons)
g3 <- g2[complete.cases(g2$Ym),]

Ym  <- g3$Ym
Ysd <- g3$Ysd

N <- length(Ym)

DMA <- g3$DMA

Pop <- g3$Pop/sd(g3$Pop,na.rm=T)
BlackRatio <- g3$BlackRatio

Wealth <- g3$Wealth/sd(g3$Wealth,na.rm=T)
Gini <- g3$Gini

Ones <- rep(1,N)

DMAIndex <- goog$dmaindex
GoogleRacism <- goog$raciallychargedsearch

########### There is missing data here, so we need to find the max and min of emprical data
WhiteAssault <- g3$WhiteAssault
MaxWhiteAssault <- max(WhiteAssault,na.rm=T)
MinWhiteAssault <- min(WhiteAssault,na.rm=T)

BlackAssault <- g3$BlackAssault
MaxBlackAssault <- max(BlackAssault,na.rm=T)
MinBlackAssault <- min(BlackAssault,na.rm=T)

WhiteWeapons <- g3$WhiteWeapons
MaxWhiteWeapons <- max(WhiteWeapons,na.rm=T)
MinWhiteWeapons <- min(WhiteWeapons,na.rm=T)

BlackWeapons <- g3$BlackWeapons
MaxBlackWeapons <- max(BlackWeapons,na.rm=T)
MinBlackWeapons <- min(BlackWeapons,na.rm=T)

##################### Now we code where the missing data occur, and deal with a few cases of zeros.
# There are two ways to account for zeros, either take out logs later, or treat zeros as missing data.
# Here we code the small number of zeros as missing data parameters. It is as if the rates are zero due lack of 
# reporting, not becuase of complete absence of crime. Check robustness by running the very last regression model below,
# and commenting out the 4 lines with ifelse(XX==0,NA,XX) below.

 WhiteAssault <- ifelse(WhiteAssault==0,NA,WhiteAssault)
MissCumSumWhiteAssault <-cumsum(is.na(WhiteAssault))
MissCumSumWhiteAssault <-ifelse(MissCumSumWhiteAssault ==0,1,MissCumSumWhiteAssault )
NonMissWhiteAssault  <-ifelse(is.na(WhiteAssault ),0,1)
NmissWhiteAssault <-sum(is.na(WhiteAssault ))
WhiteAssault [is.na(WhiteAssault )]<-9999999

 BlackAssault <- ifelse(BlackAssault==0,NA,BlackAssault)
MissCumSumBlackAssault <-cumsum(is.na(BlackAssault))
MissCumSumBlackAssault <-ifelse(MissCumSumBlackAssault ==0,1,MissCumSumBlackAssault )
NonMissBlackAssault  <-ifelse(is.na(BlackAssault ),0,1)
NmissBlackAssault <-sum(is.na(BlackAssault ))
BlackAssault [is.na(BlackAssault )]<-9999999

 WhiteWeapons <- ifelse(WhiteWeapons==0,NA,WhiteWeapons)
MissCumSumWhiteWeapons <-cumsum(is.na(WhiteWeapons))
MissCumSumWhiteWeapons <-ifelse(MissCumSumWhiteWeapons ==0,1,MissCumSumWhiteWeapons )
NonMissWhiteWeapons  <-ifelse(is.na(WhiteWeapons ),0,1)
NmissWhiteWeapons <-sum(is.na(WhiteWeapons ))
WhiteWeapons [is.na(WhiteWeapons )]<-9999999

# If not coding zeros as missing data, then run the line below to set the single case of a zero denominator to the distribution min
# WhiteWeapons[104] <- min(WhiteWeapons[which(WhiteWeapons>0)])

 BlackWeapons <- ifelse(BlackWeapons==0,NA,BlackWeapons)
MissCumSumBlackWeapons <-cumsum(is.na(BlackWeapons))
MissCumSumBlackWeapons <-ifelse(MissCumSumBlackWeapons ==0,1,MissCumSumBlackWeapons )
NonMissBlackWeapons  <-ifelse(is.na(BlackWeapons ),0,1)
NmissBlackWeapons <-sum(is.na(BlackWeapons ))
BlackWeapons [is.na(BlackWeapons )]<-9999999

model_dat  <-list(
N=N,
Ym=Ym,
Ysd=Ysd,

MissCumSumWhiteAssault=MissCumSumWhiteAssault,
NonMissWhiteAssault=NonMissWhiteAssault,
NmissWhiteAssault=NmissWhiteAssault,
WhiteAssault=WhiteAssault,
MaxWhiteAssault=MaxWhiteAssault,
MinWhiteAssault=MinWhiteAssault,

MissCumSumBlackAssault=MissCumSumBlackAssault,
NonMissBlackAssault=NonMissBlackAssault,
NmissBlackAssault=NmissBlackAssault,
BlackAssault=BlackAssault,
MaxBlackAssault=MaxBlackAssault,
MinBlackAssault=MinBlackAssault,

MissCumSumWhiteWeapons=MissCumSumWhiteWeapons,
NonMissWhiteWeapons=NonMissWhiteWeapons,
NmissWhiteWeapons=NmissWhiteWeapons,
WhiteWeapons=WhiteWeapons,
MaxWhiteWeapons=MaxWhiteWeapons,
MinWhiteWeapons=MinWhiteWeapons,

MissCumSumBlackWeapons=MissCumSumBlackWeapons,
NonMissBlackWeapons=NonMissBlackWeapons,
NmissBlackWeapons=NmissBlackWeapons,
BlackWeapons=BlackWeapons,
MaxBlackWeapons=MaxBlackWeapons,
MinBlackWeapons=MinBlackWeapons,

BlackRatio=BlackRatio,
Pop=Pop,

Wealth=Wealth,
Gini=Gini,

Ones=Ones,

DMAIndex=DMAIndex,
GoogleRacism=GoogleRacism,
DMA=DMA
 )

##############################################################################################################STAN MODEL Code
model_code<-"
########################################################################################################## Data Block
data {
################################ In Stan we need to define the array types of each peice of data
int<lower=0> N;

vector[N] Ym;
vector<lower=0>[N] Ysd;

vector<lower=0>[N] BlackRatio;
vector<lower=0>[N] Pop;

vector<lower=0>[N] Wealth;
vector<lower=0>[N] Gini;

int DMA[N];
vector[201] GoogleRacism;

int MissCumSumWhiteAssault[N];
int NonMissWhiteAssault[N];
int NmissWhiteAssault;
vector[N] WhiteAssault;
real MaxWhiteAssault;
real MinWhiteAssault;

int MissCumSumBlackAssault[N];
int NonMissBlackAssault[N];
int NmissBlackAssault;
vector[N] BlackAssault;
real MaxBlackAssault;
real MinBlackAssault;

int MissCumSumWhiteWeapons[N];
int NonMissWhiteWeapons[N];
int NmissWhiteWeapons;
vector[N] WhiteWeapons;
real MaxWhiteWeapons;
real MinWhiteWeapons;

int MissCumSumBlackWeapons[N];
int NonMissBlackWeapons[N];
int NmissBlackWeapons;
vector[N] BlackWeapons;
real MaxBlackWeapons;
real MinBlackWeapons;

vector[N] Ones;
}

parameters {
############################ Now we declare the parameters to be estimated
 vector[10] Theta;      # Regression parameters
 vector[N] log_Y;       # Outcome data with measurement error represented
 real<lower=0> Sigma;   # SD
 
 real<lower=25,upper=155> iHate; # Use parameter to impute one missing data point for the Hate data
 
 ############################## Use parameters for missing data points or zeros in the crime rate data
 real<lower=MinWhiteAssault,upper=MaxWhiteAssault> iWhiteAssault[NmissWhiteAssault];
 real<lower=MinBlackAssault,upper=MaxBlackAssault> iBlackAssault[NmissBlackAssault];
 real<lower=MinWhiteWeapons,upper=MaxWhiteWeapons> iWhiteWeapons[NmissWhiteWeapons];
 real<lower=MinBlackWeapons,upper=MaxBlackWeapons> iBlackWeapons[NmissBlackWeapons];
 }

transformed parameters{
############################### Now merge data and parameters for missing data
 vector<lower=0>[N] MeanAssault;
 vector<lower=0>[N] RatioAssault;
 
 vector<lower=0>[N] MeanWeapons;
 vector<lower=0>[N] RatioWeapons;
 
 vector<lower=0>[N] DataHate;

########################### Insert missing data parameter into vector on hate
for(t in 1:N){
 DataHate[t] =   if_else(DMA[t]==156,iHate,GoogleRacism[DMA[t]] );
 }

########################### Here we both merge data and parameters for missing data, and define the population-weighted mean
# crime rate and the crime rate ratio for each county. The if_else function inserts either the data, or the missing data parameter,
# and in the MeanAssault or MeanWeapons lines, the BlackRatio variable is used to create a weighted crime rate average.

for(t in 1:N){
 MeanAssault[t] = ((1-BlackRatio[t])*if_else(NonMissWhiteAssault[t], WhiteAssault[t], iWhiteAssault[MissCumSumWhiteAssault[t]]))+(BlackRatio[t]*if_else(NonMissBlackAssault[t], BlackAssault[t], iBlackAssault[MissCumSumBlackAssault[t]]));
 RatioAssault[t] = if_else(NonMissBlackAssault[t], BlackAssault[t], iBlackAssault[MissCumSumBlackAssault[t]])/if_else(NonMissWhiteAssault[t], WhiteAssault[t], iWhiteAssault[MissCumSumWhiteAssault[t]]);

 MeanWeapons[t] = ((1-BlackRatio[t])*if_else(NonMissBlackWeapons[t], BlackWeapons[t], iBlackWeapons[MissCumSumBlackWeapons[t]])) +(BlackRatio[t]*if_else(NonMissWhiteWeapons[t], WhiteWeapons[t], iWhiteWeapons[MissCumSumWhiteWeapons[t]]));
 RatioWeapons[t] = if_else(NonMissBlackWeapons[t], BlackWeapons[t], iBlackWeapons[MissCumSumBlackWeapons[t]])/if_else(NonMissWhiteWeapons[t], WhiteWeapons[t], iWhiteWeapons[MissCumSumWhiteWeapons[t]]);
}
}

model {
###################### Now run model
vector[N] Mu;

log_Y ~ normal(Ym,Ysd); # Model uncertianty on risk ratio of police shooting
Theta ~ cauchy(0,5);    # Weak regression priors
Sigma ~ exponential(1); # SD

#Mu = ( Theta[1]*(Ones)  );               # Intercept only model

#Mu = ( Theta[1] + Theta[2]*log(Pop)  );  # Intercept plus population mode

#Mu = ( Theta[1] + Theta[2]*log(Pop) + Theta[3]*log(BlackRatio)  );
#Mu = ( Theta[1] + Theta[2]*log(Pop) + Theta[3]*log(Wealth) );
#Mu = ( Theta[1] + Theta[2]*log(Pop) + Theta[3]*log(Gini)   );
#Mu = ( Theta[1] + Theta[2]*log(Pop) + Theta[3]*log(DataHate)   );
#Mu = ( Theta[1] + Theta[2]*log(Pop) + Theta[3]*log(MeanAssault) + Theta[4]*log(RatioAssault)  );
#Mu = ( Theta[1] + Theta[2]*log(Pop) + Theta[3]*log(MeanWeapons) + Theta[4]*log(RatioWeapons)   );

#Mu = ( Theta[1] + Theta[2]*log(Pop) + Theta[3]*log(BlackRatio) + Theta[4]*log(Wealth) );
#Mu = ( Theta[1] + Theta[2]*log(Pop) + Theta[3]*log(BlackRatio) + Theta[4]*log(Gini)   );
#Mu = ( Theta[1] + Theta[2]*log(Pop) + Theta[3]*log(BlackRatio) + Theta[4]*log(DataHate)   );
#Mu = ( Theta[1] + Theta[2]*log(Pop) + Theta[3]*log(BlackRatio) + Theta[4]*log(MeanAssault) + Theta[5]*log(RatioAssault)   );
#Mu = ( Theta[1] + Theta[2]*log(Pop) + Theta[3]*log(BlackRatio) + Theta[4]*log(MeanWeapons) + Theta[5]*log(RatioWeapons)   );

#Mu = ( Theta[1] + Theta[2]*log(Pop) + Theta[3]*log(BlackRatio) + Theta[4]*log(Wealth) + Theta[5]*log(Gini)   );
#Mu = ( Theta[1] + Theta[2]*log(Pop) + Theta[3]*log(BlackRatio) + Theta[4]*log(Wealth) + Theta[5]*log(DataHate)   );
#Mu = ( Theta[1] + Theta[2]*log(Pop) + Theta[3]*log(BlackRatio) + Theta[4]*log(Wealth) + Theta[5]*log(MeanAssault) + Theta[6]*log(RatioAssault)   );
#Mu = ( Theta[1] + Theta[2]*log(Pop) + Theta[3]*log(BlackRatio) + Theta[4]*log(Wealth) + Theta[5]*log(MeanWeapons) + Theta[6]*log(RatioWeapons)   );

#Mu = ( Theta[1] + Theta[2]*log(Pop) + Theta[3]*log(BlackRatio) + Theta[4]*log(Gini) + Theta[5]*log(DataHate)   );
#Mu = ( Theta[1] + Theta[2]*log(Pop) + Theta[3]*log(BlackRatio) + Theta[4]*log(Gini) + Theta[5]*log(DataWhiteAssault) + Theta[6]*log(RatioAssault)   );
#Mu = ( Theta[1] + Theta[2]*log(Pop) + Theta[3]*log(BlackRatio) + Theta[4]*log(Gini) + Theta[5]*log(DataWhiteWeapons) + Theta[6]*log(RatioWeapons)   );

#Mu = ( Theta[1] + Theta[2]*log(Pop) + Theta[3]*log(BlackRatio) + Theta[4]*log(Wealth) + Theta[5]*log(DataHate)  + Theta[6]*log(MeanAssault) + Theta[7]*log(RatioAssault)   );
#Mu = ( Theta[1] + Theta[2]*log(Pop) + Theta[3]*log(BlackRatio) + Theta[4]*log(Wealth) + Theta[5]*log(DataHate)  + Theta[6]*log(MeanWeapons) + Theta[7]*log(RatioWeapons)   );

#Mu = ( Theta[1] + Theta[2]*log(Pop) + Theta[3]*log(BlackRatio) + Theta[4]*log(Gini) + Theta[5]*log(DataHate)  + Theta[6]*log(MeanAssault) + Theta[7]*log(RatioAssault)   );
#Mu = ( Theta[1] + Theta[2]*log(Pop) + Theta[3]*log(BlackRatio) + Theta[4]*log(Gini) + Theta[5]*log(DataHate)  + Theta[6]*log(MeanWeapons) + Theta[7]*log(RatioWeapons)   );

 Mu = ( Theta[1] + Theta[2]*log(Pop) + Theta[3]*log(BlackRatio) + Theta[4]*log(Gini) + Theta[5]*log(Wealth) + Theta[6]*log(DataHate)  + Theta[7]*log(MeanWeapons) + Theta[8]*log(RatioWeapons)  + Theta[9]*log(MeanAssault) + Theta[10]*log(RatioAssault)  );

# And, just to check, remove the logs on the RHS for everything except population
# Mu = ( Theta[1] + Theta[2]*log(Pop) + Theta[3]*(BlackRatio) + Theta[4]*(Gini) + Theta[5]*(Wealth) + Theta[6]*(DataHate)  + Theta[7]*(MeanWeapons) + Theta[8]*(RatioWeapons)  + Theta[9]*(MeanAssault) + Theta[10]*(RatioAssault)  );

log_Y ~  normal(Mu,Sigma); # Model outcomes
}
"


################################################################################ Fit the Model IN STAN!
iter<-20000
warmup<-2000
fitKilling <- stan(model_code=model_code, data = model_dat, thin=1, iter = iter, warmup=warmup,chains = 1,refresh=10, pars=c("Theta","Sigma"))

print(fitKilling,digits_summary=4,pars=c("Theta","Sigma"))






