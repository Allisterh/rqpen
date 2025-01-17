rm(list=ls(all=TRUE))
library(devtools)
devtools::unload("rqPen")
install_github("bssherwood/rqpen")
3
library(rqPen)
library(hrqglas)


library(hqreg)
library(glmnet)

set.seed(1)

x <- matrix(rnorm(100*8,sd=1),ncol=8)

y <- 1 + x[,1] + 3*x[,3] - x[,8] + rt(100,3)
g <- c(1,1,1,1,2,2,3,3)
tvals <- c(.25,.75)

m1 <- rq.pen.cv(x,y)
plot(m1,septau=FALSE)
m2 <- rq.pen.cv(x,y,alg="br")
m3 <- rq.pen.cv(x,y,penalty="Ridge")
m4 <- rq.pen.cv(x,y,penalty="ENet",a=.5)

m6 <- rq.pen.cv(x,y,penalty="SCAD")
m7 <- rq.pen.cv(x,y,penalty="MCP")

m1 <- rq.pen.cv(x,y,tau=c(.1,.3,.7))
m2 <- rq.pen.cv(x,y,alg="br",tau=c(.1,.3,.7))
m3 <- rq.pen.cv(x,y,penalty="Ridge",tau=c(.1,.3,.7))
m4 <- rq.pen.cv(x,y,penalty="ENet",a=.5,tau=c(.1,.3,.7))
m5 <- rq.pen.cv(x,y,penalty="aLASSO",tau=c(.1,.3,.7))
m6 <- rq.pen.cv(x,y,penalty="SCAD",tau=c(.1,.3,.7))
m7 <- rq.pen.cv(x,y,penalty="MCP",tau=c(.1,.3,.7),a=c(3,4,5))

m1 <- rq.group.pen.cv(x,y,tau=c(.1,.3,.7),groups=g)
m2 <- rq.group.pen.cv(x,y,penalty="gAdLASSO",tau=c(.1,.3,.7),groups=g)
m3 <- rq.group.pen.cv(x,y,penalty="gSCAD",tau=c(.1,.3,.7),a=c(3,4,5),groups=g)
plot(m3,septau=FALSE)
m4 <- rq.group.pen.cv(x,y,penalty="gMCP",tau=c(.1,.3,.7),a=c(3,4,5),groups=g)

x <- matrix(rnorm(100*8,sd=10),ncol=8)
y <- 1 + x[,1] + 3*x[,3] - x[,8] + rt(100,3)
m1 <- rq.pen(x,y,tau=c(.1,.5,.7),penalty="SCAD",a=c(3,4))
plot(m1,a=3,tau=.7)
plot(m1)
mlist <- NULL
for(i in 1:6){
mlist[i] <- paste("Plot",i)
}
plot(m1,main=mlist)








