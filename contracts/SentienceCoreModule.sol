// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./reference/src/ERC6551Registry.sol";
import "./reference/src/examples/upgradeable/ERC6551AccountUpgradeable.sol";

contract SentienceCoreModule is Initializable, ERC721Upgradeable, ERC721PausableUpgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable, UUPSUpgradeable {
    
    event InventoryCreated(address indexed inventory, address nft, uint256 id);
    
    // Standard 6551 Inventory definitions
    ERC6551Registry public registry;
    ERC6551AccountUpgradeable public account;
    // Mapping to store token URIs
    mapping(uint256 => string) private _tokenURIs;
    bool public universal_uri;
    string public baseURI;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) initializer public {
        __ERC721_init("CoreModule", "SENTS");
        __ERC721Pausable_init();
        __Ownable_init(initialOwner);
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();

        registry = new ERC6551Registry();
        account = new ERC6551AccountUpgradeable();
    }

    function setURI(uint256 tokenId, string memory _uri, bool _all) public onlyOwner {
        _tokenURIs[tokenId] = _uri;
        universal_uri = _all;
        if(universal_uri) baseURI = _uri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if(universal_uri) return baseURI;
        string memory _uri = _tokenURIs[tokenId];
        return _uri;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {       
        _safeMint(to, tokenId);
        address implementation = _createAccount(address(this), tokenId);

        emit InventoryCreated(implementation, address(this), tokenId);
    }

    function safeBurn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721Upgradeable, ERC721PausableUpgradeable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    // Standard 6551
    function _createAccount(address _nft, uint256 _id) internal returns (address) {
        return registry.createAccount(
            address(account),
            bytes32(0),
            block.chainid, // chainId
            _nft,
            _id
        );
    }
}
