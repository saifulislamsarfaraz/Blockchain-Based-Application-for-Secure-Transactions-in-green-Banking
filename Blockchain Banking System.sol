pragma solidity ^0.5.1;

contract Owned{
    address owner;
    
    constructor()public{
        owner = msg.sender;
    }
    
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
}

contract MyContract is Owned{
    
    struct AccountHolder
    {
        uint acc_no;
        string acc_name;
        uint acc_balance;
        string branch_name;
        uint phone_no;
        uint loan;
    }
    
    struct Cheque
    {
        uint cheque_no;
        uint issuer;
        uint reciver;
        uint amount;
        string status;
    }
    
    struct Loan
    {
        uint loan_no;
        uint acc_no;
        uint loan_amt;
    }
     
    uint count = 110;
    uint l = 0;
    mapping(uint => AccountHolder) AccountMap;
    mapping(uint => Cheque) PendingChequeMap;
    mapping(uint => Cheque) AllChequeMap;
    mapping(uint => Loan) LoanMap;
    uint [] private custAcc;
    uint [] private loans;
    uint [] private PendingCheques;
    uint [] private ProcessedCheques;
    
    function OpenAccount(string memory _accname,string memory _branchName, uint _phoneNo) onlyOwner  public 
    {
        uint _accno = ++count;
        AccountHolder storage account = AccountMap[_accno];
        account.acc_name = _accname;
        account.acc_no = _accno;
        account.acc_balance = 0;
        account.branch_name = _branchName;
        account.phone_no = _phoneNo;
        account.loan = 0;
        custAcc.push(_accno) -1;
    }
    
    function Deposit(uint accno, uint amount) public payable
    {
        AccountMap[accno].acc_balance = AccountMap[accno].acc_balance + amount;
    }
    
     function Withdrawl(uint accno, uint amount) public payable
    {
        require((amount)<=AccountMap[accno].acc_balance, "Balance is not sufficient"); 
        AccountMap[accno].acc_balance = AccountMap[accno].acc_balance - amount;
    }
    
    function setChequeData(uint _chequeno,uint _issuer, uint _reciver, uint _amount) onlyOwner public
    {
        Cheque storage cheques = PendingChequeMap[_chequeno];
        cheques.cheque_no = _chequeno;
        cheques.issuer = _issuer;
        cheques.reciver = _reciver;
        cheques.amount = _amount;
        cheques.status = "Pending";
        PendingCheques.push(_chequeno) -1;
        AllChequeMap[_chequeno] = PendingChequeMap[_chequeno];
    }
    
    function ProcessCheque(uint chequeno) public payable
    {
        uint index;
        AllChequeMap[chequeno].status = "Processed";
        require((PendingChequeMap[chequeno].amount)<=(AccountMap[PendingChequeMap[chequeno].issuer].acc_balance), "Balance is not sufficient"); 
        AccountMap[PendingChequeMap[chequeno].issuer].acc_balance = AccountMap[PendingChequeMap[chequeno].issuer].acc_balance - PendingChequeMap[chequeno].amount;
        AccountMap[PendingChequeMap[chequeno].reciver].acc_balance = AccountMap[PendingChequeMap[chequeno].reciver].acc_balance + PendingChequeMap[chequeno].amount;
        ProcessedCheques.push(chequeno) -1;
        delete (PendingChequeMap[chequeno]);
        for(uint i=0;i<PendingCheques.length;i++)
        {
            if(PendingCheques[i] == chequeno)
            index = i;
        }
        for (uint i = index; i < PendingCheques.length - 1; i++) 
        {
            uint temp = PendingCheques[i];
            PendingCheques[i] = PendingCheques[i + 1];
            PendingCheques[i + 1] = temp;
        }
        delete PendingCheques[PendingCheques.length - 1];
        PendingCheques.length--;
    }
    
    function CloseAccount(uint accno) public payable
    {
        uint index;
        delete (AccountMap[accno]);
        for(uint i=0;i<custAcc.length;i++)
        {
            if(custAcc[i] == accno)
            index = i;
        }
        for (uint i = index; i < custAcc.length - 1; i++) 
        {
            uint temp = custAcc[i];
            custAcc[i] = custAcc[i + 1];
            custAcc[i + 1] = temp;
        }
        delete custAcc[custAcc.length - 1];
        custAcc.length--;
    }
    
    function GetLoan(uint accno, uint amount) onlyOwner public
    {
        require(((AccountMap[accno].loan)<50000), "you loan limit is maxed out");
        uint loanno = ++l;
        Loan storage CustLoan = LoanMap[loanno];
        CustLoan.acc_no = accno;
        CustLoan.loan_amt = amount;
        loans.push(loanno) -1;
        if((AccountMap[accno].loan + amount)<=50000)
        {
        AccountMap[accno].acc_balance = AccountMap[accno].acc_balance + amount;
        AccountMap[accno].loan = AccountMap[accno].loan + amount;
        }
    }
    
    function PayLoan(uint accno, uint amount) onlyOwner public
    {
        require((amount)<=(AccountMap[accno].acc_balance), "Balance is not sufficient"); 
        if(AccountMap[accno].loan < amount)
        {
            AccountMap[accno].loan = 0;
            AccountMap[accno].acc_balance = AccountMap[accno].acc_balance + ( amount - AccountMap[accno].loan );
        }
        else
        {
            AccountMap[accno].loan = AccountMap[accno].loan - amount;
        }
    }
    
    function getLoanData(uint loanno) view public returns(uint,uint,uint)
    {
        return (LoanMap[loanno].loan_no, LoanMap[loanno].acc_no, LoanMap[loanno].loan_amt);
    }
    
    function getAccountData(uint accno) view public returns(string memory,uint,uint,string memory,uint,uint)
    {
        return (AccountMap[accno].acc_name,AccountMap[accno].acc_no,AccountMap[accno].acc_balance,AccountMap[accno].branch_name,AccountMap[accno].phone_no, AccountMap[accno].loan);
    }
    
    function getChequeData(uint chequeno) view public returns(uint,uint,uint,uint,string memory)
    {
        return (AllChequeMap[chequeno].cheque_no, AllChequeMap[chequeno].issuer, AllChequeMap[chequeno].reciver, AllChequeMap[chequeno].amount, AllChequeMap[chequeno].status);
    }
    
    function getAccounts() view public returns(uint, uint[] memory)
    {
        return (custAcc.length, custAcc);
    }
    
    function getLoans() view public returns(uint, uint[] memory)
    {
        return (loans.length, loans);
    }

    function getPendingCheques() view public returns(uint, uint[] memory)
    {
        return (PendingCheques.length, PendingCheques);
    }
    
     function getProseccedCheques() view public returns(uint, uint[] memory)
    {
        return (ProcessedCheques.length, ProcessedCheques);
    }
}