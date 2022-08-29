/****************************************************************************************************************************************************
** This Source Code is referred to the original AutctionFactory forked from woojong92/Teamchainer_BlockChainProject 
** It must not be used for commercial purposes.
****************************************************************************************************************************************************/
pragma solidity ^0.5.0;

import "./EstateFactory.sol";
import "./GPAToken.sol";
import "./SafeMath.sol";

contract TradingFactory {

    EstateFactory public estateFactory;
    GPAToken public gpaToken;

    //manager : TradingFactory Seller
    address public manager;

    constructor(EstateFactory _estateFactory, GPAToken _gpaToken) public {
        manager = msg.sender; //TradingFactory 컨트랙트 의장 address
        estateFactory = EstateFactory(_estateFactory);
        gpaToken = GPAToken(_gpaToken);
    }
    
    EstateTrading private estateTrading;     //EstateTrading 컨트랙트
    address public estateSeller;    //EstateTrading컨트랙트 소유자 주소
    
    event NewTrading();

    //EstateTrading 컨트랙트 생성
    function createTrading(address _seller) public {
        EstateTrading newEstateTrading = new EstateTrading(manager, _seller, estateFactory, gpaToken); //msg.sender: Trading 사용자의 주소로 변경
        estateSeller = _seller;
        emit NewTrading();
    }

    //생성된 EstateTrading 컨트랙트 리턴
    function getEstateTradings() public view returns (EstateTrading){
        return estateTrading;
    }
}

// 거래만을 위한 contract (공시가격 등에 대한 정합성 체크는 다른 contract 생성으로 판단)
contract EstateTrading {

    using SafeMath for uint256; // now 사용 목적

    EstateFactory public estateFactory;
    GPAToken public gpaToken;
    
    enum STATE { REQUESTED, ACCEPTED, COMPLETED, DISCARDED } // 거래상태: 거래 요청, 참여자간 수락, 거래 완료 등
    
    //TradeLedger 구조체 (매매대금의 특정 퍼센티지는 관례적이므로 해당 contract에서는 제외...직접 입력.)
    struct TradeLedger {
        string description; //설명
        uint estateId;  //토큰id        
        uint contractDate; //계약일자
        uint dueDate; //잔금일자(기한)
        uint[] agreementDate; //약정일자(배열로 선언. 중도금/기한 등에 대한 여러날짜 push가능)...contract: 법적 구속력, agreement: 법적 구속력 없음
        uint[] agreementAmount; // (중도금/기한 등 약정일자 => 약정금액), 이체 약정/합의한 금액
        uint tradePrice; //매매대금
        uint accTransferAmount; //누적이체금액
        STATE tradingStatus; //거래상태
    }

    //TradeLedger 구조체를 담는 변수
    TradeLedger public tradeLedger;

    address public manager;  //TradingFactory 컨트랙트 manager (코스콤) 
    address public seller;   //EstateTrading 컨트랙트 Seller (매도인)
    address public buyer;    //매수인

    mapping(uint=>uint) private agreementAmountMapper; // (중도금/기한 등 약정일자 => 약정금액), 이체 약정/합의한 금액 mapper
    mapping(uint=>uint) private transferAmountMapper; // (중도금/기한 등 이체일자 => 이체금액), 실제 이체한 금액 mapper

    //EstateTrading 생성자
    constructor(address _manager, address _seller, EstateFactory _estateFactory, GPAToken _gpaToken) public {
        manager = _manager; 
        seller = _seller;
        estateFactory = _estateFactory; //ERC721 토큰 사용 => 매도인 매물로 사용.
        gpaToken = _gpaToken;   //ERC20 토큰 사용 => 매수인 잔액으로 사용.
    }

    //TradeLedger 생성: manager 권한
    function createTradeLedger(string memory _description,
                               uint _estateId, 
                               uint _contractDate, 
                               uint _dueDate,
                               uint[] memory _agreementDate, 
                               uint[] memory _agreementAmount,
                               uint[] memory _transferAmount,                               
                            //    mapping(uint=>uint) memory _agreementAmount, // mapping can only have a data location of "storage"
                            //    mapping(uint=>uint) memory _transferAmount,
                               address _manager,
                               address _buyer,
                               uint _tradePrice,
                               uint _accTransferAmount,
                               STATE _tradingStatus) public {
        //_esteteId의 owner여부 확인
        require(estateFactory.ownerOf(_estateId) == seller,"not seller's estateId");
        require(manager == _manager,"only Manager accessible!");        
        require(_agreementDate.length == _agreementAmount.length,"invalid size of agreement amount");
        require(_agreementDate.length == _transferAmount.length,"invalid size of transfer amount");

        tradeLedger.description = _description;
        tradeLedger.estateId = _estateId;
        tradeLedger.contractDate = _contractDate;
        tradeLedger.dueDate = _dueDate;
        tradeLedger.agreementDate = _agreementDate;
        tradeLedger.agreementAmount = _agreementAmount;
        tradeLedger.tradePrice = _tradePrice;
        tradeLedger.accTransferAmount = _accTransferAmount;
        tradeLedger.tradingStatus = _tradingStatus;
        
        for(uint i=0; i < _agreementDate.length; i++) {
            agreementAmountMapper[_agreementDate[i]] = _agreementAmount[i];
            transferAmountMapper[_agreementDate[i]] = _transferAmount[i];
        }
        buyer = _buyer;
    }
    
    //매수인 약정 이행 request => 매도인 accept, 최종 부동산 이전시 코스콤 approve 방식으로 업데이트 예정...
    
    // 매수인 약정 금액 이체 요청
    event requestTransferAmountEvent(address buyer, uint transferAmount, STATE tradingStatus);
    function requestTransferAmount(address _buyer, uint _transferAmount, uint _transferDate) public 
                                                                                             checkTradeLedger(_transferDate, _transferAmount) //거래 원장 체크
                                                                                             checkBalance(_buyer, _transferAmount) //매수인 잔고 체크
                                                                                             returns(bool) {
        require(_buyer == buyer, "invalid Buyer to participate in trade.");
        
        TradeLedger storage _tradeLedger = tradeLedger;

        // 약정된 날짜에 해당하는 약정 금액 일치할 경우에만, 금액 이체.
        if( _transferAmount == agreementAmountMapper[_transferDate]){
            gpaToken.transferFrom(_buyer, seller, _transferAmount); 
            
            transferAmountMapper[_transferDate] = _transferAmount;
            _tradeLedger.accTransferAmount += _transferAmount;
            
            _tradeLedger.tradingStatus = STATE.REQUESTED;
            
            emit requestTransferAmountEvent(_buyer, _transferAmount, _tradeLedger.tradingStatus);            
            return true;
        } else {
            emit requestTransferAmountEvent(_buyer, _transferAmount, _tradeLedger.tradingStatus);
            return false;
        }
    }
    
    // 거래 원장 체크
    modifier checkTradeLedger(uint _transferDate, uint _transferAmount) {
        _;
        TradeLedger memory _tradeLedger = tradeLedger;
        
        bool isTradable = false;
        for(uint i=0; i < _tradeLedger.agreementDate.length; i++) {
            if(_tradeLedger.agreementDate[i] == _transferDate)
                isTradable = true;
        }
        require(isTradable == true, "not satisfied date to trade");
        require(transferAmountMapper[_transferDate] == _transferAmount, "not satisfied date to trade");
    }

    // 잔고 체크
    modifier checkBalance(address _participant, uint _transferAmount) {
        _;
        require(gpaToken.balanceOf(_participant) >= _transferAmount);
    }
    
    // 상대거래자(매도인) 승인
    event acceptTransferAmountEvent(address seller, STATE tradingStatus);    
    function acceptTransferAmount(address _seller) public returns(bool) {
        require(_seller == seller, "invalid Seller to participate in trade.");
        
        TradeLedger storage _tradeLedger = tradeLedger;
        require(_tradeLedger.tradingStatus == STATE.REQUESTED, "check the state of trading phases");
        
        // 약정 당일까지 누적 이체된 금액이 약정 총 금액과 일치하는지 체크
        uint _totAgreementAmount = 0;
        for(uint i=0; i < _tradeLedger.agreementDate.length; i++) {
            _totAgreementAmount += agreementAmountMapper[_tradeLedger.agreementDate[i]];
        }
        
        if(_tradeLedger.accTransferAmount >= _totAgreementAmount) {
            _tradeLedger.tradingStatus = STATE.ACCEPTED;
            
            emit acceptTransferAmountEvent(_seller, _tradeLedger.tradingStatus);
            return true;
        } else {
        
            emit acceptTransferAmountEvent(_seller, _tradeLedger.tradingStatus);
            return false;
        }
    }
    
    // 만기일자(dueDate)에 금액 확인후, 부동산 이전 처리. 부동산 토큰 내부적으로 approval 수행.
    event transferEstateEvent(address seller, address buyer, uint tokenId, uint32 time);
 
    function transferEstate(address _seller, address _buyer, uint _tokenId, uint _transferDate) public returns(bool) {        
        require(seller == _seller, "invalid buyer");
        require(buyer == _buyer, "invalid buyer");
        require(getOwnerOfToken(_tokenId) == _seller, "tokenId error");

        TradeLedger storage _tradeLedger = tradeLedger;
        require(_tradeLedger.dueDate == _transferDate, "Transfer-Estate shall be performed on due-date");
        require(_tradeLedger.accTransferAmount >= _tradeLedger.tradePrice, "The accumulated transfer-amount must be greater or equal to the trade price.");
  
        estateFactory.transferFrom(_seller, _buyer, _tokenId);
        
        _tradeLedger.tradingStatus = STATE.COMPLETED;
        
        emit transferEstateEvent(_seller, _buyer, _tokenId, uint32(now));
        return true;
    }

    function getOwnerOfToken(uint _tokenId) public view returns (address) {
        return estateFactory.ownerOf(_tokenId);
    }

    function discardTrading() public returns(bool) {
        tradeLedger.tradingStatus = STATE.DISCARDED;
        return true;
    }

    function getApprovedEstateId(uint _estateId) public view returns(address) {
        return estateFactory.getApproved(_estateId);
    }
    
    function getTradingInfo() public view returns(string memory, 
                                                  uint, 
                                                  uint, 
                                                  uint, 
                                                  uint[] memory,
                                                  uint[] memory,
                                                  uint, 
                                                  uint,
                                                  STATE,
                                                  address,
                                                  address){
        return (tradeLedger.description, 
                tradeLedger.estateId,
                tradeLedger.contractDate,
                tradeLedger.dueDate, 
                tradeLedger.agreementDate, 
                tradeLedger.agreementAmount, 
                tradeLedger.tradePrice,
                tradeLedger.accTransferAmount,
                tradeLedger.tradingStatus,
                seller,
                buyer);
    }

    function getCompleteTrading() public view returns(STATE) {
        return tradeLedger.tradingStatus;
    }

    function getManagerAddress() public view returns(address) {
        return manager;
    }
    
    function getSellerAddress() public view returns(address) {
        return seller;
    }
    
    function getBuyerAddress() public view returns(address) {
        return buyer;
    }
}
