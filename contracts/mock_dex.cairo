%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import storage_read, storage_write
from starkware.cairo.common.math import unsigned_div_rem

struct dex_stats:
    member reserve_1 : felt
    member reserve_2 : felt
    member fee : felt
end

@storage_var
func saved_stats() -> (dex_stat : dex_stats):
end

@view
func get_reserves_and_fee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (fee : felt, reserve1 : felt, reserve2 : felt):
    let (stats : dex_stats) = saved_stats.read()
    return(stats.fee,stats.reserve_1,stats.reserve_2) 
end

@view
func trade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _trade_amount : felt) -> (trade_return : felt):
    let (stats : dex_stats) = saved_stats.read()
    tempvar amount_in_with_fee = _trade_amount * stats.fee
    tempvar numerator = amount_in_with_fee * stats.reserve_2
    tempvar denominator = stats.reserve_1 * 1000 + amount_in_with_fee
    let (res,_) = unsigned_div_rem(numerator,denominator)
    return(res)	
end

@external
func set_reserves_and_fee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _fee : felt, _reserve_1 : felt, _reserve_2 : felt):
    
    saved_stats.write(dex_stats(_reserve_1,_reserve_2,_fee))
    
    return()
end


