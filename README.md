# Blockchain_RealEstate

### The Test Case ###

#manager: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
#seller: 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
#buyer: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4

real estat info.
{
	"0": "estateId: 1",
	"1": "estateOwner: 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db",
	"2": "estateName: test",
	"3": "estateAddr: test",
	"4": "estateStatus: 1",
	"5": "officialPrice: 100",
	"6": "salePrice: 100"
}

### The Test Result ###

![01_1_GPAToken_mint_setBalance](https://user-images.githubusercontent.com/42527020/190063828-aa620fc2-c409-4e97-8b1b-6be22becbee0.png)
![01_1_GPAToken_mint_getApproval_allowance](https://user-images.githubusercontent.com/42527020/190063800-4da131b5-ca67-4d3a-93f9-59dea0826250.png)
1. GPA Token minted and get approval for allowance - 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2



![02_EstateFactory_mint](https://user-images.githubusercontent.com/42527020/190063881-3f0f3d52-b3c0-42d3-9a6e-d31a5abbfaf0.png)
2. Real-Estate Token minted - 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db



![03_1_TradingFactory_createTradeLedger](https://user-images.githubusercontent.com/42527020/190063903-7f3320d3-5202-472b-a2b9-17bbbf966912.png)
3-1. Create Trade Ledger - 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2


![03_2_TradingFactory_requestTransferAmount_transferGPAToken](https://user-images.githubusercontent.com/42527020/190063931-25405bd4-126a-4b9e-9062-564f7d28ef9f.png)
3-2. Request to transfer GPA Token to buy the real estate - 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4


![03_3_GPAToken_buyer_balance](https://user-images.githubusercontent.com/42527020/190063948-9a44a175-3813-434f-be4a-7b4cdfe63a45.png)
3-3. Check the GPA Token balance of the buyer - 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4


![03_4_GPAToken_seller_balance](https://user-images.githubusercontent.com/42527020/190063987-63611960-16be-4e1a-a783-2e53e254ca89.png)
3-4. Check the GPA Token balance of the seller - 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db


![03_5_TradingFactory_acceptTransferAmount](https://user-images.githubusercontent.com/42527020/190064007-ec6d074c-9699-42e4-8491-125b31967499.png)
3-5. Accept the tansfer amount from the seller - 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db


![03_6_TradingFactory_transferEstate](https://user-images.githubusercontent.com/42527020/190064021-48dfc11d-bae3-4d35-a366-f290880fe5dc.png)
3-6. Transfer the real estate Token from the seller to the buyer - 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2


![04_EstateFactory_ownerOf](https://user-images.githubusercontent.com/42527020/190064037-80228f69-964b-454e-8a87-1f675081a038.png)
4. Check if the buyer now owns the Real-Estate Token - 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4

