pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract nftRegistration is ERC20{
    address manager;
    
    uint public pollNumber=0;//Current voting number
    bool public runPoll = false;//Check poll time
    mapping (uint=>uint) public pollTime;
    struct nft{
        address senderAddress;
        address nftAddress; 
        uint index;
        string description;
        uint votes;
    }
      
    mapping (uint=>nft) public pollWinner;//Winners of each voting held
    uint public allTokenHolders=1;//All voters and token takers
  
    //List of nft
    nft[] public nfts;
    mapping (address=>  mapping (uint=>uint)) public voteRewards; //Everey vote reward
    mapping (address=> uint) public allWithraw;//All receipts so far
    mapping (address=> mapping (uint=>address[])) public targetVotes;//All NFTs voted by an address in each period
    mapping (address=> mapping (uint=>uint)) public allVotes;//The total number of votes for each address in each voting period
    constructor() public ERC20("Nft marketing token", "NMT") {
        manager = msg.sender;
        _mint(address(this), (100000000 * 10**18));
    }
    modifier onlyowner() {
        require(msg.sender==manager);
        _;
    }

    //The amount received from the right vote to the winning NFT
    function checkMywins(address sender) private view returns(uint) {
          uint amount = 0;
          for(uint i=1;i<pollNumber;i++){
               for(uint j=0;j<targetVotes[msg.sender][i].length;j++){
                   if(targetVotes[msg.sender][i][j]==pollWinner[i].nftAddress){
                       amount = amount + ((20000*10**18)/pollWinner[i].votes);
                   }
               }
          }
          return amount;
    }

    function checkVoteRewards(address sender) private view returns(uint) {
          uint amount = 0;
          for(uint i=1;i<pollNumber;i++){
            amount = amount + ((voteRewards[msg.sender][i]*10000*10**18)/pollWinner[i].votes);
          }
          return amount;
    }

    //If I am a creditor from the contract, pay me
    function withrawAmount() public {
        uint winAmount = checkMywins(msg.sender);
        uint withrawll = allWithraw[msg.sender];
        uint voteReward = checkVoteRewards(msg.sender);
        uint allAmount = winAmount+voteReward;
        require(withrawll<allAmount , "HAVE_NOT_WITHRAW");
        ERC20(address(this)).transfer(msg.sender , allAmount-withrawll);
        allWithraw[msg.sender] = allAmount;
     }

    //NFT wins
    function showWinner() private view returns(uint) {
           uint maxvote=0;
            uint index = 0;

            for(uint i=0;i<nfts.length;i++){
                if(maxvote<nfts[i].votes){
                    maxvote=nfts[i].votes;
                    index = i;
                }
            }
            return index;
    }

    
    function createPoll() public{
         require(runPoll==false , "IS_RUN");
         runPoll = true;
         pollNumber++;
         pollTime[pollNumber] = block.timestamp; 
    } 
    function closePoll() private{
         if(block.timestamp>=(pollTime[pollNumber]+(1*60*1)) && pollTime[pollNumber]!=0){
            uint index = showWinner();
            pollWinner[pollNumber].nftAddress = nfts[index].nftAddress;
            pollWinner[pollNumber].votes = nfts[index].votes;
            pollWinner[pollNumber].senderAddress = nfts[index].senderAddress;
            ERC20(address(this)).transfer(pollWinner[pollNumber].senderAddress , 20000*10**18);
            runPoll = false;
            pollTime[pollNumber] = 0;
            delete nfts;
         }
    }

    function registerNft(address nftAddress ,uint nftIndex ,string memory nftDescription) public payable{
        require(runPoll , "NOT_POLLTIME");
        require(msg.value>=100000000000000*allTokenHolders, "NOT_PAY");
        nft memory newItem;  
        newItem.nftAddress = nftAddress;
        newItem.senderAddress = msg.sender;
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
       
        targetVotes[msg.sender][pollNumber].push(nftItem.nftAddress);
        allVotes[msg.sender][pollNumber]++;
        if(balanceOf(msg.sender)==0){
           allTokenHolders++;
        }
        nfts[item].votes++;
        voteRewards[msg.sender][pollNumber]++;
        closePoll();

     }



}
