pragma solidity 0.5.0;

library Unit {
    
    // Ether Units
    function toWei(uint val) public pure returns(uint) { return val * 1 wei; }
    
    function toSzabo(uint val) public pure returns(uint) { return val * 1 szabo; }
    
    function toFinney(uint val) public pure returns(uint) { return val * 1 finney; }
    
    function toEther(uint val) public pure returns(uint) { return val * 1 ether; }
    
    // Time Units
    function toSeconds(uint val) public pure returns(uint) { return val * 1 seconds; }
    
    function toMinutes(uint val) public pure returns(uint) { return val * 1 minutes; }
    
    function toHours(uint val) public pure returns(uint) { return val * 1 hours; }
    
    function toDays(uint val) public pure returns(uint) { return val * 1 days; }
    
    function toWeeks(uint val) public pure returns(uint) { return val * 1 weeks; }
    
    /* 
     * Approximation Warning
     *
     * Be aware that Cast.toAprxMonths(12) != Cast.toAprxYears(1)
     *
     * Cast.toAprxMonths(1) = 360 days
     * Cast.toAprxYears(1) = 365
     * 360 days != 365 days
     * 
     * Only use Cast.toAprxMonths() and Cast.toAprxYears() if these errors are tolerable.
     * If you want more precise measurements, use Cast.toDays() and Cast.toWeeks() instead.
     */
     
    // There are approximately 30 days a month on average
    // "aprx" in the function name serves as a reminder that conversions are approximations
    function toAprxMonths(uint val) public pure returns(uint) { return val * 30 days; }
    
    // Assumes there are 365 days a year
    // "aprx" in the function name serves as a reminder that conversions are approximations
    function toAprxYears(uint val) public pure returns(uint) { return val * 365 days; }
}
