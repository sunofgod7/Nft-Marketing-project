pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract nftRegistration is ERC20{
    address manager;
    bool public runPoll = false;
    uint public pollTime= 0;
    uint public allTokenHolders=1;
    //List of nft metadata
    struct nft{
        address nftAddress; 
        uint index;
        string description;
     }
    nft[] public nfts;
    mapping (address=>uint) votes; 
    mapping (address=>address[]) targetVotes;
    mapping (address=>uint) allVotes;
    constructor() public ERC20("Gold", "GLD") {
        manager = msg.sender;
        _mint(address(this), (100000000 * 10**18));
    }
    modifier onlyowner() {
        require(msg.sender==manager);
        _;
    }
    function createPoll() public onlyowner{
         runPoll = true;
         pollTime = block.timestamp;
    } 
    function closePoll() private{
         if(block.timestamp>=(pollTime+(3600*24*10)) && pollTime!=0){
            runPoll = false;
            pollTime = 0;
         }
    }
    function registerNft(address nftAddress ,uint nftIndex ,string memory nftDescription) public payable{
        require(runPoll , "NOT_POLLTIME");
        require(msg.value>=0.00001 ether , "NOT_PAY");
        nft memory newItem;  
        newItem.nftAddress = nftAddress;
        newItem.index = nftIndex;
        newItem.description = nftDescription;
        nfts.push(newItem);
        closePoll();
    }
    function voteRegistration(uint item) public{
        nft memory nftItem = nfts[item];
        require(runPoll , "NOT_POLLTIME");
        bool targetVote = false;
        for (uint i = 0; i < targetVotes[msg.sender].length; i++) {
            if (targetVotes[msg.sender][i] == nftItem.nftAddress) {
                targetVote = true;
            }
         }
        require(!targetVote , "DOUBLE_VOTE");
        require(allVotes[msg.sender]<=10 , "ALOT_VOTES");
        votes[nftItem.nftAddress]++;
        targetVotes[msg.sender].push(nftItem.nftAddress);
        allVotes[msg.sender]++;
        if(balanceOf(msg.sender)==0){
           allTokenHolders++;
        }
        ERC20(address(this)).transfer(msg.sender , 1*10**18/allTokenHolders);
        closePoll();
    }



}
