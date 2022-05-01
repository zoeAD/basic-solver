%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import assert_le, assert_nn_le, unsigned_div_rem, sqrt
from starkware.cairo.common.pow import pow
from starkware.cairo.common.math_cmp import (is_in_range, is_le, is_le_felt, is_nn, is_nn_le, is_not_zero)
from starkware.starknet.common.syscalls import storage_read, storage_write
from starkware.cairo.common.alloc import alloc

const base = 1000000000000000000 # 1.0
const stepsize = 100000000000000000 # 0.05
const dex_len = 3
const max_step_reductions = 3

@storage_var
func dex_list(index : felt) -> (dex : felt): 
end

@contract_interface
namespace IDex:
    func get_reserves_and_fee() -> (xFee : felt, reserve1 : felt, reserve2 : felt):
    end
end

#Perform a trade between two assets using the specified solver
@view
func solve{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amountIn : felt) -> (amountOut : felt):

    alloc_locals
    let (stats : felt*) = alloc()
    getDexStats(9,stats)    

    let (k) = pow(stats[6],2)
    let (l) = pow(stats[1],2)
    let (o) = pow(stats[0],2)
    let (t) = pow(amountIn,2)
   
 
    let (arr : felt*) = alloc()
    assert arr[0] = amountIn*stats[2]
    assert arr[1] = stats[6]*stats[1]
    assert arr[2] = 1000*stats[5]
    assert arr[3] = amountIn*stats[0]
    assert arr[4] = arr[0]*stats[8]
    assert arr[5] = k
    assert arr[6] = l
    assert arr[7] = amountIn*l*k
    assert arr[8] = amountIn*arr[1]
    assert arr[9] = o
    assert arr[10] = o*stats[4]
    assert arr[11] = arr[3]*stats[4]
    assert arr[12] = 1000*stats[3]
    assert arr[13] = amountIn*stats[1]
    assert arr[14] = t
    assert arr[15] = stats[6]*l*t
    assert arr[16] = t*arr[10]    
    assert arr[17] = stats[7] * 1000

    #tempvar ptr : preCalcs* = new preCalcs(a,d,e,f,i,j,k,l,m,n,o,p,q,r,s,t,u,v)
    #tempvar arr : felt* = new (a,d,e,f,i,j,k,l,m,n,o, p, q, r, s, t, u, v)
    
    #Hardcoded starting values for x and y at 0.1
    let ( x, y, amountOut) = findWeights(100000000000000000,100000000000000000,0,arr,stepsize,max_step_reductions,0,0,amountIn) #counter is set to 0 
        
    #let (xToBuy) = fmul(x,amountOut)
    #let (yToBuy) = fmul(y,amountOut)
    #let (zToBuy) = fmul((base-(x+y)),amountOut) 
    #performTrades(xToBuy,yToBuy,zToBuy)
    
    #transform for display purposes
    let (res,_) = unsigned_div_rem(amountOut,1000000000000000000)
    return(res)
end

@view
func findWeights{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    x : felt, y : felt, arr_len : felt, arr : felt*, stepsize : felt, stepsize_reductions : felt, amountOut : felt, counter : felt, amountToBuy : felt) -> (x : felt, y : felt, amountOut : felt):
        
    alloc_locals    
    
    #MAX ITTERATIONS
    if counter == 20 :
        return(x,y,amountOut)
    end

    let (xgradient) = x_gradient(x, y, (base-(x+y)), 18,arr, amountToBuy)
    let (ygradient) = y_gradient(x, y,(base-(x+y)), 18,arr, amountToBuy)

    let (powerY) = pow(ygradient,2)
    let (powerX) = pow(xgradient,2)
    tempvar powerXY = powerX + powerY
    let (norm) = sqrt(powerXY)
    
    let (inverseNorm) = fdiv(base,norm)
	
    let (xgradient) = fmul(xgradient,inverseNorm)
    let (ygradient) = fmul(ygradient,inverseNorm)

    let (deltaX) = fmul(xgradient, stepsize)
    let (deltaY) = fmul(ygradient, stepsize)

    tempvar new_x = x + deltaX
    tempvar new_y = y + deltaY

    let (newAmountOut) = obj_func(new_x, new_y, (base-(new_x+new_y)),18,arr,amountToBuy)

    let (amountCheck) = is_le(newAmountOut,amountOut)
    
    #This should not be done like this, either build into the formular or reduce stepsize on fail
    #let(xyCheck) = (new_x+new_y) >= 1 Still need to check for this
    #let(xCheck) = is_nn(new_y)
    #let(yCheck) = is_nn(new_x)
    #if xCheck + yCheck != 3 :
    #    return(x,y,amountOut)
    #end

    #If less efficient, redoo with last result and smaller stepsize
    if amountCheck == 1:
        if stepsize_reductions == 0:
            return(x,y,amountOut)
        end
    
        let (new_stepsize,_) = unsigned_div_rem(stepsize,2)
        let(xx, yy, amountOutt) = findWeights(x,y,0,arr,new_stepsize,stepsize_reductions-1,amountOut,counter+1,amountToBuy)
        return(xx, yy, amountOutt)

    #Continue normaly
    else:
	let(xx, yy, amountOutt) = findWeights(new_x,new_y,0,arr,stepsize,stepsize_reductions,newAmountOut,counter+1,amountToBuy)
    	return(xx, yy, amountOutt)
    end
end

@external
func performTrades{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    xamount : felt, yamount : felt, zamount : felt) -> (amountOut : felt):
    #Imagine Trading Logic Here
    return(0)
end    


#Couldn't be bothered to make this recursive :D
@view
func getDexStats{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        stats_len : felt, stats : felt*):
        alloc_locals
 	let (dex_1) = dex_list.read(0) 	
        let (xFee,xreservesOut,xreservesIn) = IDex.get_reserves_and_fee(dex_1)
        let (dex_2) = dex_list.read(1)
	let (yFee,yreservesOut,yreservesIn) = IDex.get_reserves_and_fee(dex_2)
	let (dex_3) = dex_list.read(2)
	let (zFee,zreservesOut,zreservesIn) = IDex.get_reserves_and_fee(dex_3)
    	
	stats[0] = xFee 
	stats[1] = yFee
	stats[2] = zFee
	stats[3] = xreservesIn
        stats[4] = xreservesOut
        stats[5] = yreservesIn
	stats[6] = yreservesOut
        stats[7] = zreservesIn
        stats[8] = zreservesOut
	
	return()
end

@view
func obj_func{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    x : felt, y : felt, z : felt, arr_len : felt, arr : felt*, amount : felt) -> (amountOut : felt):
    alloc_locals    

    tempvar b = base-(z+y)
    tempvar c = base-(x+z)
    tempvar d = base-(x+y)
    
    let(temp1) = fmul(b, arr[11])
    let(temp2) = fmul(b, arr[3])
    let(temp4) = fdiv(temp1,arr[12] + temp2)

    let(temp5) = fmul(c, arr[8])
    let(temp6) = fmul(c, arr[13])
    let(temp8) = fdiv(temp5,arr[2] + temp6)

    let(temp9) = fmul(d, arr[4])
    let(temp10) = fmul(d, arr[0])
    let(temp12) = fdiv(temp9,arr[17] + temp10) 
    
    return(temp12+temp8+temp4)
end

@view
func x_gradient{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    x : felt, y : felt, z : felt, arr_len : felt,arr : felt*, amount : felt) -> (amountOut : felt):
    alloc_locals
    
    tempvar b = base-(x+y)
    tempvar c = base-(x+z)
    let (g) = fmul(arr[3],x)
    let (h) = fmul(arr[1],c)

    let (_numerator1) = fmul(arr[4],b)
    let (_semiDenom1) = fmul(arr[0],b)
    let (_res1) = fdiv(_numerator1,arr[17]+_semiDenom1)

    let (_numerator2) = fmul(arr[7],c)
    let (_denom1) = pow(h+arr[2],2)
    let (_res2) = fdiv(_numerator2,_denom1)

    let (_res3) = fdiv(arr[8],arr[2]+h)

    let (_numerator3) = fmul(arr[10],x)
    let (_semiDenom2) = fmul(1000,x)
    let (_denom2) = pow(_semiDenom2+g,2)
    let (_res4) = fdiv(_numerator3,_denom2)

    let (_res5) = fdiv(arr[11],g+arr[12])

    return(_res1+_res2-_res3+_res4+_res5)
end

@view
func y_gradient{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    x : felt, y : felt, z : felt, arr_len : felt,arr : felt*, amount : felt) -> (amountOut : felt):
    alloc_locals

    tempvar b = base-(x+y)
    tempvar d = base-(z+y)
    let (f) = fmul(arr[3],d)
    tempvar w = arr[12]+f
    let (g) = fmul(arr[13],y)
    tempvar h = g+arr[2]

    let (_numerator1) = fmul(arr[4],b)
    let (_semiDenom1) = fmul(arr[0],b)
    let (_res1) = fdiv(_numerator1,_semiDenom1+arr[17])
    
    let (_numerator2) = fmul(arr[15],y)
    let (_denom1) = pow(h,2)
    let (_res2) = fdiv(_numerator2,_denom1)
    
    let (_numerator3) = fmul(arr[16],d)
    let (_denom2) = pow(w,2)
    let (_res3) = fdiv(_numerator3,_denom2)

    let (_res4) = fdiv(arr[8],h)
    
    let (_res5) = fdiv(arr[11],w) 

    return(_res1-_res2+_res3+_res4-_res5)
   
end

#For simplicity sake this is kept non-recursive, as we also have a fixed number of DEXes atm.
@external
func set_dex{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    dex_address_1 : felt, dex_address_2 : felt, dex_address_3 : felt):
    dex_list.write(0,dex_address_1)
    dex_list.write(1,dex_address_2)
    dex_list.write(2,dex_address_3)
    return()
end

@view
func fmul{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    x : felt, y : felt) -> (z : felt):
    let (division,_) = unsigned_div_rem(x*y,base)
    return(division)
end  
  
@view
func fdiv{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    x : felt, y : felt) -> (z : felt):
    let (division,_) = unsigned_div_rem(x*base,y)
    return(division)
end 

