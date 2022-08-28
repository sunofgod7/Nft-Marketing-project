pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract nftRegistration is ERC20{
    address manager;
    
    uint public pollNumber=0;
    bool public runPoll = false;
    mapping (uint=>uint) public pollTime;
    struct winner{
        address winnerAddress;
        uint voteCounts;
    }
    mapping (uint=>winner) public pollWinner;
    uint public allTokenHolders=1;
    //List of nft
    struct nft{
         address nftAddress; 
        uint index;
        string description;
        uint votes;
    }
    
    nft[] public nfts;

    mapping (address=> mapping (uint=>address[])) public targetVotes;
    mapping (address=> mapping (uint=>uint)) public allVotes;
    constructor() public ERC20("Nft marketing token", "NMT") {
        manager = msg.sender;
        _mint(address(this), (100000000 * 10**18));
    }
    modifier onlyowner() {
        require(msg.sender==manager);
        _;
    }

    function showWinner() private view returns(address) {
           uint maxvote=0;
           address winnerAddress;

            for(uint i=0;i<nfts.length;i++){
                if(maxvote<nfts[i].votes){
                    maxvote=nfts[i].votes;
                    winnerAddress = nfts[i].nftAddress;
                }
            }
            return winnerAddress;
    }

    function winnerVoteCounts() private view returns(uint) {
           uint maxvote=0;
            for(uint i=0;i<nfts.length;i++){
                if(maxvote<nfts[i].votes){
                    maxvote=nfts[i].votes;
                }
            }
            return maxvote;
    }

    function createPoll() public onlyowner{
         require(runPoll==false , "IS_RUN");
         runPoll = true;
         pollNumber++;
         pollTime[pollNumber] = block.timestamp;
    } 
    function closePoll() private{
         if(block.timestamp>=(pollTime[pollNumber]+(1*60*1)) && pollTime[pollNumber]!=0){
            pollWinner[pollNumber].winnerAddress = showWinner();
            pollWinner[pollNumber].voteCounts = winnerVoteCounts();
            runPoll = false;
            pollTime[pollNumber] = 0;
            delete nfts;
         }
    }
    function registerNft(address nftAddress ,uint nftIndex ,string memory nftDescription) public payable{
        require(runPoll , "NOT_POLLTIME");
        require(msg.value>=0.00001 ether , "NOT_PAY");
        nft memory newItem;  
        newItem.nftAddress = nftAddress;
        newItem.index = nftIndex;
        newItem.description = nftDescription;
        newItem.votes = 1;
        nfts.push(newItem);
        closePoll();

    }
    function voteRegistration(uint item) public{
        require(runPoll , "NOT_POLLTIME");
        nft memory nftItem = nfts[item];
        bool targetVote = false;
        for (uint i = 0; i < targetVotes[msg.sender][pollNumber].length; i++) {
            if (targetVotes[msg.sender][pollNumber][i] == nftItem.nftAddress) {
                targetVote = true; 
            } 
        }
        require(!targetVote , "DOUBLE_VOTE");
        require(allVotes[msg.sender][pollNumber]<=10 , "ALOT_VOTES");
        nftItem.votes++;
        targetVotes[msg.sender][pollNumber].push(nftItem.nftAddress);
        allVotes[msg.sender][pollNumber]++;
        if(balanceOf(msg.sender)==0){
           allTokenHolders++;
        }
        ERC20(address(this)).transfer(msg.sender , 1*10**18/allTokenHolders);
        closePoll();

     }



}
