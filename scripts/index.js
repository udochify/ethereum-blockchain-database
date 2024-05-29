var contract;
const udo = require('../udo');
const express = require('express');
const hre = require("hardhat");
const DatabaseModule = require("../ignition/modules/Database");

const app = express();

app.use(express.urlencoded({
    extended: true
}));

app.use(express.json());

app.get('/user', async (req, res) => {
    try {
        const user = await contract.database.getUser(req.query.address);
        if (user[user.length-1]) {
          return res.json({success:true, user: "" + user});
        } else {
            res.json({error: true, message: "The user does not exist"});
            console.log("Error: The user does not exist");
        }
    } catch (error) {
        res.json({error: true, message: "Blockchain server error. Contact admin."});
        console.log("Error: Blockchain server error 8 " + error);
    }
});

app.get('/file', async (req, res) => {
    try {
        const file = await contract.database.getFile(req.query.address);
        if (file.exists) {
          return res.json({success:true, file: "" + file});
        } else {
            res.json({error: true, message: "The file does not exist"});
            console.log("Error: The file does not exist");
        }
    } catch (error) {
        res.json({error: true, message: "Blockchain server error. Contact admin."});
        console.log("Error: Blockchain server error 9 " + error);
    }
});

app.get('/userfiles', async (req, res) => {
    try {
        const userfiles = await contract.database.getUserfiles(req.query.address);
        return res.json({success:true, userfiles: "" + userfiles});
    } catch (error) {
        res.json({error: true, message: "Blockchain server error. Contact admin."});
        console.log("Error: Blockchain server error 10 " + error);
    }
});

app.get('/fileusers', async (req, res) => {
    try {
        const fileusers = await contract.database.getFileuser(req.query.address);
        return res.json({success:true, fileusers: "" + fileusers});
    } catch (error) {
        res.json({error: true, message: "Blockchain server error. Contact admin."});
        console.log("Error: Blockchain server error 11 " + error);
    }
});

app.get('/sharedfiles', async (req, res) => {
    try {
        const sharedfiles = await contract.database.getSharedfiles(req.query.address);
        return res.json({success:true, sharedfiles: "" + sharedfiles});
    } catch (error) {
        res.json({error: true, message: "Blockchain server error. Contact admin."});
        console.log("Error: Blockchain server error 12 " + error);
    }
});

app.get('/contacts', async (req, res) => {
    try {
        const contacts = await contract.database.getUser(req.query.address);
        return res.json({success:true, contacts: "" + contacts});
    } catch (error) {
        res.json({error: true, message: "Blockchain server error. Contact admin."});
        console.log("Error: Blockchain server error 13 " + error);
    }
});

app.post('/register', async (req, res) => {
    try {
        const wallet = await hre.ethers.Wallet.createRandom();
        const newuser = await contract.database.addUser(wallet.address, req.body.name, req.body.email);
        if(newuser) {
            await contract.database.once("UserAdded" , async() => {
                res.json({success: true, address: wallet.address, key: wallet.privateKey, message: "new account created"});
                console.log("Total number of users: " + await contract.database.usercount());
                console.log("New user account created: \n" + await contract.database.getUser(wallet.address));
            });
        }
        else {
            res.json({error: true, message: "Unable to create account, try again"});
            console.log("Error: User Account creation failed");
        }
    } catch (error) {
        res.json({error: true, message: "Blockchain server error. Contact admin."});
        console.log("Error: Blockchain server error 14 " + error);
    }
});

app.post('/upload', async (req, res) => {
    try {
        const wallet = new hre.ethers.Wallet(req.body.key);
        if(req.body.address === wallet.address) {
            const wallet = hre.ethers.Wallet.createRandom();
            const newfile = await contract.database.addFile(req.body.address, wallet.address, req.body.name, req.body.path, req.body.hash);
            if(newfile){
                await contract.database.once("FileAdded" , async() => {
                    res.json({success: true, address: wallet.address, message: "new file created"});
                    console.log("Total number of Files: " + await contract.database.filecount());
                    console.log("New file created: \n" + await contract.database.getFile(wallet.address));
                });
            } else {
                res.json({error: true, message: "Unable to create file. Try again."});
                console.log("Error: File creation failed");
            }
        } else {
            res.json({error: true, message: "Invalid private key. Contact admin."});
            console.log("Error: Invalid private key");
        }
    } catch (error) {
        res.json({error: true, message: "Blockchain server error. Contact admin."});
        console.log("Error: Blockchain server error 1 " + error);
    }
});

app.post('/addcontact', async (req, res) => {
    try {
        const newcontact = await contract.database.addContact(req.body.user, req.body.address);
        if(newcontact){
            await contract.database.once("ContactAdded" , async() => {
                res.json({success: true, message: "new contact added"});
                console.log("Total number of contacts for " + req.body.user + ":\n" + await contract.database.getContacts(req.body.user));
            });
        } else {
            res.json({error: true, message: "Unable to add contact. Try again."});
            console.log("Error: File creation failed");
        }
    } catch (error) {
        res.json({error: true, message: "Blockchain server error. Contact admin."});
        console.log("Error: Blockchain server error 2 " + error);
    }
});

app.post('/crc', async (req, res) => {
    try {
        const result = await contract.database.matchFile(req.body.address, req.body.hash);
        if(result) {
            console.log("file: " + req.body.address + " passed CRC. Status: " + result); 
            res.json({success:true, status: "Passed", message: "Passed CRC"});
            console.log(result);
        } else {
            console.log("file: " + req.body.address + " failed CRC. Status: " + result);
            res.json({success:true, status: "Failed", message: "Failed CRC"});
        }
    } catch (error) {
        res.json({error: true, message: "Blockchain server error. Contact admin."});
        console.log("Error: Blockchain server error 3 " + error);
    }
});

app.post('/sharefilewithsome', async (req, res) => {
    try {
        const result = await contract.database.shareFileWithSome(req.body.owner, req.body.address, JSON.parse(req.body.users));
        if(result){
            await contract.database.once("FileSharedWithSome" , async() => {
                res.json({success: true, message: "file shared successfully"});
                console.log("File " + req.body.address + " shared successfully\n");
                console.log("All users sharing file " + req.body.address + ": \n");
                console.log(await contract.database.getFileusers(req.body.address));
                console.log("\nAll files shared with " + req.body.owner + ": \n");
                console.log(await contract.database.getSharedfiles(req.body.owner));
            });
        } else {
            res.json({error: true, message: "Unable to share file. Try again."});
            console.log("Error: File sharing failed");
        }
    } catch (error) {
        res.json({error: true, message: "Blockchain server error. Contact admin."});  
        console.log("Error: Blockchain server error 4 " + error);     
    }
});

app.post('/unsharefilewithone', async (req, res) => {
    try {
        const result = await contract.database.unshareFile(req.body.owner, req.body.address, req.body.user);
        if(result){
            await contract.database.once("FileUnshared" , async() => {
                res.json({success: true, message: "file unshared successfully"});
                console.log("File " + req.body.address + " unshared successfully with " + req.body.user + "\n");
                console.log("All users sharing file " + req.body.address + ": \n");
                console.log(await contract.database.getFileusers(req.body.address));
                console.log("\nAll files shared with " + req.body.owner + ": \n");
                console.log(await contract.database.getSharedfiles(req.body.owner));
            });
        } else {
            res.json({error: true, message: "Unable to share file. Try again."});
            console.log("Error: File sharing failed");
        }
    } catch (error) {
        res.json({error: true, message: "Blockchain server error. Contact admin."});  
        console.log("Error: Blockchain server error 5 " + error);     
    }
});

app.post('/unsharefilewithsome', async (req, res) => {
    try {
        const result = await contract.database.unshareFileWithSome(req.body.owner, req.body.address, JSON.parse(req.body.users));
        if(result){
            await contract.database.once("FileUnsharedWithSome" , async() => {
                res.json({success: true, message: "file unshared successfully"});
                console.log("File " + req.body.address + " unshared successfully\n");
                console.log("All users sharing file " + req.body.address + ": \n");
                console.log(await contract.database.getFileusers(req.body.address));
                console.log("\nAll files shared with " + req.body.owner + ": \n");
                console.log(await contract.database.getSharedfiles(req.body.owner));
            });
        } else {
            res.json({error: true, message: "Unable to share file. Try again."});
            console.log("Error: File sharing failed");
        }
    } catch (error) {
        res.json({error: true, message: "Blockchain server error. Contact admin."});  
        console.log("Error: Blockchain server error 6 " + error);     
    }
});

app.post('/deletefile', async (req, res) => {
    try {
        const wallet = new hre.ethers.Wallet(req.body.key);
        if(req.body.owner === wallet.address) {
            const result = await contract.database.deleteFile(req.body.owner, req.body.address);
            if(result){
                await contract.database.once("FileDeleted" , async() => {
                    res.json({success: true, message: "file deleted successfully"});
                    console.log("File with address: " + req.body.address + " has been deleted successfully");
                    console.log("Total number of Files: " + await contract.database.filecount());
                });
            } else {
                res.json({error: true, message: "Unable to delete file. Try again."});
                console.log("Error: File deletion failed");
            }
        } else {
            res.json({error: true, message: "Invalid private key. Contact admin."});
            console.log("Error: Invalid private key");
        }
    } catch (error) {
        res.json({error: true, message: "Blockchain server error. Contact admin."});  
        console.log("Error: Blockchain server error 7 " + error);     
    }
});

app.listen(udo.PORT, async () => {
    contract = await hre.ignition.deploy(DatabaseModule, {
        parameters: { Database: {authKey: udo.AUTH_KEY} },
    });

    console.log(`Server is listening at port ${udo.PORT}` + " contract address is " + contract.database.target);
});