//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IOffchainOracle.sol";
import "./interfaces/IChainlinkOracle.sol";
import "./interfaces/IUniswapV2Pair.sol";


contract Oracle {
    IOffchainOracle public oracle = IOffchainOracle(0x7F069df72b7A39bCE9806e3AfaF579E54D8CF2b9);
    IERC20 public USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    IChainlinkOracle public usdcOracle = IChainlinkOracle(0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7);

    uint8 public constant decimals = 6;

    function getRateUSD(IERC20 token) public view returns (uint256) {
        uint256 rateUSDC = oracle.getRate(token, USDC, true);
        ( , int256 answer, , , ) = usdcOracle.latestRoundData();
        return (rateUSDC * 1e8) / uint256(answer);
    }

    function getLpRateUSD(IUniswapV2Pair lpToken) public view returns (uint256) {
        ( , int256 answer, , , ) = usdcOracle.latestRoundData();

        IERC20Metadata token0 = IERC20Metadata(lpToken.token0());
        IERC20Metadata token1 = IERC20Metadata(lpToken.token1());
        (uint112 reserve0, uint112 reserve1, ) = lpToken.getReserves();

        uint256 rate0USDC = (oracle.getRate(token0, USDC, true) * 1e8) / uint256(answer);
        uint256 rate1USDC = (oracle.getRate(token1, USDC, true) * 1e8) / uint256(answer);

        uint256 denominator0 = 10 ** token0.decimals();
        uint256 denominator1 = 10 ** token1.decimals();

        uint256 token0TotalUSD = (rate0USDC * reserve0) / denominator0;
        uint256 token1TotalUSD = (rate1USDC * reserve1) / denominator1;

        uint256 totalUSD = token0TotalUSD + token1TotalUSD;

        return (totalUSD * (10**lpToken.decimals())) / lpToken.totalSupply();
    }
}
