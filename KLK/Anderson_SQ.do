*(1)**empowerment1
foreach i in a b c d e f g h i{
	gen household_12`i' = (SEC5_q7`i' > 1)
	}
	
foreach x of varlist household_12a household_12b household_12c household_12d household_12e household_12f household_12g household_12h household_12i{
         local i = `i' + 1
         rename `x' household_12`i'
		 }

*Convert to z scores using the control group (treated == 0) at baseline (time == 0)
forvalues count = 1/9{
		su household_12`count' 	if (treated == 0 & time == 0)
		local MyMean 	= r(mean)
		local MySD 		= r(sd)	
		gen household_12`count'_z 	= (household_12`count' - `MyMean')/`MySD'
	}
*Impute missing values at the treatment assignment group mean...
forvalues count = 1/9{
		capture drop YHatTemp
		
		reg household_12`count'_z treated  
		predict YHatTemp
		
		replace household_12`count'_z 	= YHatTemp if household_12`count'_z == .
	}
*Calculate the covariance matrix and the weights...

correl household_12*_z, covar
matrix MyCovar 		= r(C)	
matrix CovarInv  	= syminv(MyCovar)

matrix MyOnes 		= J(rowsof(CovarInv), 1, 1)

matrix MyWeights 	= syminv(MyOnes' * CovarInv * MyOnes) * (MyOnes' * CovarInv)

svmat MyWeights, names(weightemp1)

forvalues count = 1/9{
		gen weightedemp1_`count' 	= household_12`count'_z * weightemp1`count'[1]
	}
egen  	empowerment_1 	= rsum(weightedemp1*)

forvalues count = 1/9{
		reg household_12`count'_z treated
	}

* Finally, regress the weighted outcome on the treatment dummy...
reg empowerment_1 treated
