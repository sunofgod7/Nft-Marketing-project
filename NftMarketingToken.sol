pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
 contract nftRegistration is ERC20{
  
    address manager1;
    address manager2;
    address manager3;
    
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
    mapping (uint=>uint) public soldToken;//Tokens sold in each voting held
    mapping (uint=>nft) public pollWinner;//Winners of each voting held
    uint public allTokenHolders=1;//All voters and token takers
  
    //List of nft
    nft[] public nfts;
    mapping (address=>  mapping (uint=>uint)) public marketReward; //Everey market vote reward
    mapping (address=>  mapping (uint=>uint)) public voteRewards; //Everey vote reward
    mapping (address=> uint) public allWithraw;//All receipts so far
    mapping (address=> mapping (uint=>address[])) public targetVotes;//All NFTs voted by an address in each period
    mapping (address=> mapping (uint=>uint)) public allVotes;//The total number of votes for each address in each voting period
    constructor() public ERC20("Nft marketing token", "NMT") {
        manager1 = address(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db);
        manager2 = address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        manager3 = address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
        _mint(address(this), (100000000 * 10**18));
    }
    modifier onlyowners() {
        require(msg.sender==manager1 || msg.sender==manager2 || msg.sender==manager3 ,"ONLY_MANAGERS");
        _;
    }

    function withraw(address manager) public onlyowners{
        payable(manager).transfer(address(this).balance);
    }
     
    //The amount received from the right vote to the winning NFT
    function checkMywins() private view returns(uint) {
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

    //The amount received from votes
    function checkVoteRewards() private view returns(uint) {
          uint amount = 0;
          for(uint i=1;i<pollNumber;i++){
            amount = amount + ((voteRewards[msg.sender][i]*10000*10**18)/pollWinner[i].votes);
          }
          return amount;
    }

    //The amount received from marketing votes
    function checkMarketingRewards() private view returns(uint) {
          uint amount = 0;
          for(uint i=1;i<pollNumber;i++){
            amount = amount + ((marketReward[msg.sender][i]*20000*10**18)/pollWinner[i].votes);
          }
          return amount;
    }

    //If I am a creditor from the contract, pay me
    function withrawAmount() public {
        uint winAmount = checkMywins();
        uint voteReward = checkVoteRewards();
        uint marketingReward = checkMarketingRewards();
        uint withrawll = allWithraw[msg.sender];
        uint allAmount = winAmount+voteReward+marketingReward;
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

    //Voting can be created by any person at the right time
    function createPoll() public{
         require(runPoll==false , "IS_RUN");
         runPoll = true;
         pollNumber++;
         pollTime[pollNumber] = block.timestamp; 
    } 

    //Voting ends with the last participant
    function closePoll() private{
         if(block.timestamp>=(pollTime[pollNumber]+(1*60*1)) && pollTime[pollNumber]!=0){
            uint index = showWinner();
            pollWinner[pollNumber].nftAddress = nfts[index].nftAddress;
            pollWinner[pollNumber].votes = nfts[index].votes;
            pollWinner[pollNumber].senderAddress = nfts[index].senderAddress;
            ERC20(address(this)).transfer(pollWinner[pollNumber].senderAddress , 20000*10**18);
            if(50000-soldToken[pollNumber]>0){//burn
                _burn(address(this),(50000-soldToken[pollNumber])*10**18);
            }
            runPoll = false;
            pollTime[pollNumber] = 0;
            delete nfts;
         }
    }

    //Construction of NFT at the time of voting
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

    //Vote for NFT with special conditions
    function voteRegistration(uint item , address marketer) public{
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
        marketReward[marketer][pollNumber]++;
        closePoll();

     }
    //Construction of NFT at the time of voting
    
    //Construction of NFT at the time of voting
    //0xF9680D99D6C9589e2a93a78A04A279e509205945
    // test net  0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046
    function buyToken(uint amount) public payable{
         require(runPoll , "NOT_POLLTIME");
         require(soldToken[pollNumber]+amount<=50000,"OUT_OF_ALLOWANCE");
         require(msg.value>=(amount*10**18)/15000,"NOT_ENOUGH");
         ERC20(address(this)).transfer(msg.sender , amount*(10**18));
         soldToken[pollNumber] = soldToken[pollNumber] + amount;
    }

    
     



}
