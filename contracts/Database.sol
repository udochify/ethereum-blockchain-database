// SPDX-License-Identifier: GPL-3.0
// Author: Enwerem C. Udochukwu
// contact: udoinui@gmail.com
// date: 03/01/2023 7:37am
// gas for deployment: 4849504 for database; 794454 for IterableMap

pragma solidity >=0.8.9 <0.9.0;

import  "././libraries/IterableMap.sol";

contract Database {
    using IterableMap for IterableMap.Map;

    struct User {
        uint id;
        string name;
        string email;
        IterableMap.Map userfiles;
        IterableMap.Map otherfiles;
        IterableMap.Map contacts;
        bool exists; // will be set to true whenever this user is created; defaults to false
    }

    struct File {
        uint id;
        address owner; // owner of this file
        string name;
        uint size;
        string path;
        bytes32 crc;
        IterableMap.Map fileusers;
        bool exists; // will be set to true whenever this file is created; defaults to false
    }

    bool private unlocked = false;
    uint public usercount; // keep count of total users
    uint public filecount; // keep count of total files
    uint public maxuserid = 0; // keep track of the maximum user id
    uint public maxfileid = 0; // keep track of the maximum file id

    mapping(address => User) private users; // mapping of all user addresses to user struct instances
    mapping(address => File) private files; // mapping of all file addresses to file struct instances

    mapping(string => bool) public emails; // keep track of user emails to prevent duplicates
    mapping(string => bool) public paths; // keep track of file paths to prevent duplicates

    event FileAdded(address owneraddr, address fileaddr, string name, string path);
    event UserAdded(address useraddr, uint id, string name, string email);
    event ContactAdded(address useraddr, address contactaddr);
    event ContactRemoved(address useraddr, address contactaddr);
    event ContactsRemoved(address useraddr);
    event FileUpdated(address fileaddr, address owneraddr);
    event FileDeleted(address fileaddr, address owneraddr);
    event FileShared(address fileaddr, address owneraddr, address useraddr);
    event FileSharedWithSome(address fileaddr, address owneraddr);
    event FileSharedWithAll(address fileaddr, address owneraddr);
    event FileUnshared(address fileaddr, address owneraddr, address useraddr);
    event FileUnsharedWithSome(address fileaddr, address owneraddr);
    event FileUnsharedWithAll(address fileaddr, address owneraddr);

    modifier userExists(address addr) {
        require(users[addr].exists, "User does not exist.");
        _;
    }

    modifier userExistsNot(address addr, string memory email) {
        require(!users[addr].exists && !emails[email], "User already exists.");
        _;
    }

    modifier fileExists(address addr) {
        require(files[addr].exists, "File does not exist.");
        _;
    }

    modifier fileExistsNot(address addr, string memory path) {
        require(!files[addr].exists && !paths[path], "File already exists.");
        _;
    }

    modifier isOwner(address owneraddr, address fileaddr) {
        require(owneraddr == files[fileaddr].owner, "User is not the file owner.");
        _;
    }

    constructor(string memory authkey) {
        if(keccak256(bytes(authkey)) == keccak256(bytes("djieij3IK$KH-fjd@kf_fkkflkdQWF%HCB+362h45g=O93jdh*@?"))) {
            unlocked = true;
        }
    }

    // gas used to add first file 473919; subsequently 416249
    function addFile(address owneraddr, address fileaddr, string memory name, string memory path, string memory filestring) public userExists(owneraddr) fileExistsNot(fileaddr, path) returns(bool) {
        if(unlocked) {
            bytes memory filebytes = bytes(filestring);
            files[fileaddr].id = maxfileid++;
            files[fileaddr].owner = owneraddr;
            files[fileaddr].name = name;
            files[fileaddr].size = filebytes.length;
            files[fileaddr].path = path;
            files[fileaddr].crc = keccak256(filebytes);
            files[fileaddr].exists = true;
            users[owneraddr].userfiles.insert(fileaddr);
            paths[path] = true;
            filecount++;
            emit FileAdded(owneraddr, fileaddr, name, path);
        }
        return unlocked;
    }

    // gas used to add first user 168927; subsequently 154627
    function addUser(address useraddr, string memory name, string memory email) public userExistsNot(useraddr, email) returns(bool) {
        if (unlocked) {  
            users[useraddr].id = maxuserid++;
            users[useraddr].name = name;
            users[useraddr].email = email;
            users[useraddr].exists = true;
            emails[email] = true;
            usercount++;
            emit UserAdded(useraddr, maxuserid, name, email);
        }
        return unlocked;
    }

    function getUser(address useraddr) public view returns(uint, string memory, string memory, bool) {
        return (users[useraddr].id, users[useraddr].name, users[useraddr].email, users[useraddr].exists);
    }

    function getFile(address fileaddr) public view returns(uint, address, string memory, uint, bool) {
        return (files[fileaddr].id, files[fileaddr].owner, files[fileaddr].name, files[fileaddr].size, files[fileaddr].exists);
    }

    // gas used to add 1st contact 174994; 177624 subsequently; 40680 if contact already added
    function addContact(address useraddr, address contactaddr) public userExists(useraddr) userExists(contactaddr) returns(bool) {
        if(unlocked) {
            users[useraddr].contacts.insert(contactaddr);
            users[contactaddr].contacts.insert(useraddr);
            emit ContactAdded(useraddr, contactaddr);
        }
        return unlocked;
    }

    function getUserfiles(address useraddr) public view returns(address[] memory) {
        return users[useraddr].userfiles.getAllKeys();
    }

    function getFileusers(address fileaddr) public view returns(address[] memory) {
        return files[fileaddr].fileusers.getAllKeys();
    }

    function getContacts(address useraddr) public view returns(address[] memory) {
        return users[useraddr].contacts.getAllKeys();
    }

    function getSharedfiles(address useraddr) public view returns(address[] memory) {
        return users[useraddr].otherfiles.getAllKeys();
    }

    function updateFile(address owneraddr, address fileaddr, string memory filestring) public userExists(owneraddr) isOwner(owneraddr, fileaddr) returns(bool) {
        if(unlocked) {
            bytes memory filebytes = bytes(filestring);
            files[fileaddr].size = filebytes.length;
            files[fileaddr].crc = keccak256(filebytes);
            emit FileUpdated(fileaddr, owneraddr);
        }
        return unlocked;
    }

    // gas used is 255708 (estimated is 319635) with IterableMap
    function deleteFile(address owneraddr, address fileaddr) public userExists(owneraddr) isOwner(owneraddr, fileaddr)  returns(bool) {
        if(unlocked) {
            for (uint i = 0; i < files[fileaddr].fileusers.size(); i++) {
                users[files[fileaddr].fileusers.getKeyAtIndex(i)].otherfiles.remove(fileaddr);
            }
            users[owneraddr].userfiles.remove(fileaddr);
            delete files[fileaddr];
            delete paths[files[fileaddr].path];
            filecount--;
            emit FileDeleted(fileaddr, owneraddr);
        }
        return unlocked;
    }

    // gas used 67586 (estimated 84482)
    function removeContact(address useraddr, address contactaddr) public returns(bool) {
        if (unlocked) {
            users[useraddr].contacts.remove(contactaddr);
            users[contactaddr].contacts.remove(useraddr);
            emit ContactRemoved(useraddr, contactaddr);
        }
        return unlocked;
    }

    function removeContacts(address useraddr, address[] calldata contactaddrs) public returns(bool) {
        if(unlocked) {
            for (uint i = 0; i < contactaddrs.length; i++) {
                users[useraddr].contacts.remove(contactaddrs[i]);
                users[contactaddrs[i]].contacts.remove(useraddr);
            }
            emit ContactsRemoved(useraddr);
        }
        return unlocked;
    }

    // gas used for first file 187450; subsequnetly 190238
    function shareFile(address owneraddr, address fileaddr, address useraddr) public userExists(owneraddr) isOwner(owneraddr, fileaddr) returns(bool) {
        if(unlocked) {
            if (users[owneraddr].contacts.contains(useraddr)) {
                files[fileaddr].fileusers.insert(useraddr);
                users[useraddr].otherfiles.insert(fileaddr);
            }
            emit FileShared(fileaddr, owneraddr, useraddr);
        }
        return unlocked;
    }

    // gas to share with two persons 326233
    function shareFileWithSome(address owneraddr, address fileaddr, address[] calldata useraddrs) public userExists(owneraddr) isOwner(owneraddr, fileaddr) returns(bool) {
        if (unlocked) {
            for (uint i = 0; i < useraddrs.length; i++) {
                if (users[owneraddr].contacts.contains(useraddrs[i])) {
                    files[fileaddr].fileusers.insert(useraddrs[i]);
                    users[useraddrs[i]].otherfiles.insert(fileaddr);
                }
            }
            emit FileSharedWithSome(fileaddr, owneraddr);
        }
        return unlocked;
    }

    // gas used when using arrays 1038763 for 1st file with 7 users; 1058363 subsequently
    // gas used when using iterable maps for first file with 7users 1074549; subsequently 1094149
    function shareFileWithAll(address owneraddr, address fileaddr) public userExists(owneraddr) isOwner(owneraddr, fileaddr) returns(bool) {
        if(unlocked) {   
            for (uint i = 0; i < users[owneraddr].contacts.size(); i++) {
                users[users[owneraddr].contacts.getKeyAtIndex(i)].otherfiles.insert(fileaddr);
                files[fileaddr].fileusers.insert(users[owneraddr].contacts.getKeyAtIndex(i));
            }
            emit FileSharedWithAll(fileaddr, owneraddr);
        }
        return unlocked;
    }

    // gas used is 74249 (estimate 92811); subsequently 72009 (estimated 90011); 46301 for already unshared file
    function unshareFile(address owneraddr, address fileaddr, address useraddr) public returns(bool) {
        if(unlocked) {   
            if(users[owneraddr].contacts.contains(useraddr)) {
                users[useraddr].otherfiles.remove(fileaddr);
                files[fileaddr].fileusers.remove(useraddr);
                emit FileUnshared(fileaddr, owneraddr, useraddr);
            }
        }
        return unlocked;
    }

    function unshareFileWithSome(address owneraddr, address fileaddr, address[] calldata useraddrs) public returns(bool) {
        if(unlocked) {
            for (uint i = 0; i < useraddrs.length; i++) {
                if(users[owneraddr].contacts.contains(useraddrs[i])) {
                    users[useraddrs[i]].otherfiles.remove(fileaddr);
                    files[fileaddr].fileusers.remove(useraddrs[i]);
                }
            }
            emit FileUnsharedWithSome(fileaddr, owneraddr);
        }
        return unlocked;
    }

    // gas used for first file with 7 users 312244 (estimated is 390305) with array; subsequently for 2nd and last 257924 (estimated is 322405)
    // gas used for first file with 7 users 268924 (estimated is 336155); subsequently 255472 (estimated is 319340); for last file 205472 (estimated is 256840)
    function unshareFileWithAll(address owneraddr, address fileaddr) public isOwner(owneraddr, fileaddr) returns(bool) {
        if(unlocked) {
            for (uint i = 0; i < files[fileaddr].fileusers.size(); i++) {
                users[files[fileaddr].fileusers.getKeyAtIndex(i)].otherfiles.remove(fileaddr);
            }
            files[fileaddr].fileusers.clear();
            emit FileUnsharedWithAll(fileaddr, owneraddr);
        }
        return unlocked;
    }

    function matchFile(address fileaddr, string memory filestring) view public returns(bool) {
        return keccak256(bytes(filestring)) == files[fileaddr].crc;
    }
}