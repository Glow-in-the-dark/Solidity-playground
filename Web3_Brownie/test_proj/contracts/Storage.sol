pragma solidity >=0.8.2 <0.9.0;

contract Storage1 {
    uint256 number; // This is a state variable (i.e. a value that defines the state of the contract). 


    function store(uint256 num) public {
        number = num; // assign the parameter into the state variable
    }

    function retrieve() public view returns (uint256) {
         return number;
    }
}

contract Hello {
    string a = "Hello "; // This is a state variable (i.e. a value that defines the state of the contract). 
    string c = ",~ I Can do Web3 now!";

    function append(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return string(abi.encodePacked(_a, _b, _c));
    }

    function greet(string memory _name) public view returns(string memory){
        string memory talk = append(a,_name,c);
        return talk; 
    }

}