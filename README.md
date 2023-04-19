##Whitelist Dapp

inroduction
what you will learn

prerequisites
prior knowledge of motoko
basic knowledge of front end development using html,css anf javascript
prior knowledge of command line
code editor like vscode or sublime text
internet connection
browser
dfx installed on your machine

backend development
frontend development
local deployment

mainnet deployment 
way forward

what is motoko playground?
its an online IDE enabling wrting and testing motoko code in the browser. You can develop your progam from scratch or customize one of the ready made templates from the IDE. It is good if you dont want to go through the hustle of downloading and setting up the local environment.

what is DFX?
what is Internet Identity

How the dapp works.
This is a simple whitelist dapp that enables users to request for a whitelist position from a project.  A user logins in to the dapp using their Internet identity credentials. Once logged in, the user can view their principal id, see the status of their whirelist request and even request to be whitelisted.

On the other hand, the dapp has an admin dashboard. the admin can approve a whitelist request from the user, revoke the whitelist request, add and delete other admins. The owner of the dapp has all the priviledges that the admin has.

backend developement.

In this section, you will learn how to write the motoko code for the whitelist dapp. We will use the motoko playground IDE
at the end of this section, you shoul have something similar to this

Visit motoko playground [website](https://m7sm4-2iaaa-aaaab-qabra-cai.ic0.app/) in your browser. Select `New Motoko Project`. We will develop everything from scratch.
Copy and paste the following code into the open file `main.mo`

```motoko
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
```
We start by importing the required libraries to use in the program.
```motoko
actor class whitelistDapp(dappOwner : Principal) = {};
```
We declare an actor class and name it `whitelistDapp`. it takes in one argument `dappOwner` of type `Principal`. We want to explicitly provide the Princicpal id of the owner of the dapp owner on deployment. All the remaining code for our program will go inside the actor class declared above.

```motoko
  stable let owner : Principal = dappOwner;

  let requestBuffer = Buffer.Buffer<Principal>(20);

  let whitelistedBuffer = Buffer.Buffer<Principal>(20);

  let adminBuffer = Buffer.Buffer<Principal>(20);
```
Define a variable `owner` to hold the principal of the dapp owner. Make the owner variable persist its value across upgrades by using the [stable]() keyword. 
Declare three variables of type Buffer. Buffers are one of the data structures available in motoko. [learn more about Buffers here and why we chose them for this project]().

	* `requestBuffer`. To store the principal ids of users that request to be whitelisted
	* `whitelistedBuffer`. To store the principal Ids of users that have been whitelisted succesfully
	* `adminBuffer`. To store the principal Ids of admins.

### Helper functions
```motoko
  public func isAdmin(p : Principal) : async Bool {
    if ((p == owner)) {
      return true;
    } else if ((Buffer.contains<Principal>(adminBuffer, p, Principal.equal))) {
      return true;
    } else {
      return false;
    }

  };


  public func theOwner() : async Principal {
    return owner;
  };

```
Declare a public function `isAdmin()`. It takes in one argument of type `Principal` and returns a `Bool`. The function checks to see whether the given principal matches the onwer of the dapp, or is among the list of the approved admins.

The `theOwner()` function returns the owner of the dapp declared on deployment.

### User functions
```motoko
 public shared({ caller }) func requestWhitelist() : async Text {
    if (Buffer.contains<Principal>(requestBuffer, caller, Principal.equal)) {
      "you have already requested for a whitelist";
    } else if (Buffer.contains<Principal>(whitelistedBuffer, caller, Principal.equal)) {
      return "You are already whitelisted"
    } else {
      requestBuffer.add(caller);
      return "Request accepted. Waiting for admin confirmation";

    };
  };

  
  public shared({ caller }) func checkStatus() : async Text {
    if ((Buffer.contains<Principal>(requestBuffer, caller, Principal.equal))) {
      return "Waiting for admin confirmation.";
    } else if ((Buffer.contains<Principal>(whitelistedBuffer, caller, Principal.equal))) {
      return "Congratulations. You are whitelisted"

    } else {
      return "Status unknown. Please request for the whitelist spot";
    };
  };
```

Declare a public function `requestWhitelist()` . It takes in no argument and returns a Text. It has [shared]() keyword because we want to interact with the Id that calls the function. Inside the function we perform checks to ensure that the:
* caller is not already in the request list 
* caller is not already whitelisted
If the caller passes the two checks, we add their principal id in the `requestBuffer` and then send them a message for them to wait on the admin confirmation

In the `checkStatus()`, we first check to see whether the caller's principal is either on the waiting list or on the approved list. We then return the relevant text messages to show to the user depending on the condition.

### Admin fiunctions

```motoko
  public shared({ caller }) func whitelistUser(user : Principal) : async Text {
    if (await isAdmin(caller)) {
      var resultText : Text = "";

      for (entry in requestBuffer.vals()) {
        if (entry == user) {
          let entryIndex = Buffer.indexOf<Principal>(
            entry,
            requestBuffer,
            Principal.equal,
          );
          switch (entryIndex) {
            case (?index) {
            	ignore requestBuffer.remove(index);

                whitelistedBuffer.add(user);
              
              resultText := "User whitelisted successfully";
            };
            case (null) {
              resultText := "Request does not exist";
            };
          };

        };
      };
      return resultText;

    } else {
      "You are not approved to whitelist users";
    }

  };


  public shared({ caller }) func removeWhiteliste(user : Principal) : async Text {
    if (await isAdmin(caller)) {
      var resultText : Text = "";

      for (entry in whitelistedBuffer.vals()) {
        if (entry == user) {
          let entryIndex = Buffer.indexOf<Principal>(
            entry,
            whitelistedBuffer,
            Principal.equal,
          );
          switch (entryIndex) {
            case (?index) {
              ignore whitelistedBuffer.remove(index);
              resultText := "whitelist revoked successfully";
            };
            case (null) {
              resultText := "user does not exist";
            };
          };

        };
      };
      return resultText;

    } else {
      "You are not approved to revoke whitelists";
    }

  };
```
The `whitelistUser()` function performs the following operations.
 - Checks if the caller is the admin or the owner of the dapp
 - Searches for the entry in the `requestBuffer` that matches the user Principal
 - Removes the index from the `requestBuffer`, which in turn removes the entry
 - Adds the entry in the `whitelistedBuffer`
 - Returns a relevant text message.

The `removeWhitelist()` function performs the following operations.
- Check if the caller is the admin or the owner of the dapp
 - Searches for the entry in the `whitelistedBuffer` that matches the principal from the input
 - Gets the index of the entry
 - Removes the index from the `whitelistedBuffer`, which in turn removes that entry
 - Returns the relevant text message

 ```motoko
  public shared({ caller }) func addAdmin(newAdmin : Principal) : async Text {

    if (await isAdmin(caller)) {
      if (not Buffer.contains<Principal>(adminBuffer, newAdmin, Principal.equal)) {
        adminBuffer.add(newAdmin);
        "Admin added successfully";
      } else {
        "User already admin";
      }
    } else {
      "You are not aproved to add admins";
    }
  };

  
  public shared({ caller }) func deleteAdmin(admin : Principal) : async Text {

    if (await isAdmin(caller)) {
      var resultText : Text = "";

      for (entry in adminBuffer.vals()) {
        if (entry == admin) {
          let entryIndex = Buffer.indexOf<Principal>(
            entry,
            adminBuffer,
            Principal.equal,
          );
          switch (entryIndex) {
            case (?index) {
              ignore adminBuffer.remove(index);
              resultText := "Admin deleted successfully";
            };
            case (null) {
              resultText := "Admin does not exist";
            };
          };

        };
      };
      return resultText;

    } else {
      "You are not aproved to delete admins";
    }

  };

 ```
 The `addAmin()` function performs the following operations:
 - Checks if the caller is an admin or the owner of the dapp
 - Checks the `adminBuffer` to make sure the submitted principal is not already an admin
 - Adds the submitted principal in the `adminBuffer`
 - Returns a relevant text message in case any of the conditions happens

The `deleteAdmin()` performs the following operations.
 - Checks if the caller is an admin or the owner of the dapp
 - Checks the `adminBuffer` to make sure the submitted principal is on the admin list
 - Gets the index of the submitted principal in the `adminBuffer`.
 - Removes the index from the `adminBuffer`, which in turn removes the submitted principal(the value at that index)
 - Returns a relevant text message if any of the condition passes or fails

 ```motoko
  public shared({ caller }) func getAdminList() : async [Principal] {
    if (await isAdmin(caller)) {
      Buffer.toArray(adminBuffer);
    } else {
      [];
    };
  };

  public shared({ caller }) func getRequestList() : async [Principal] {
    if (await isAdmin(caller)) {
      Buffer.toArray(requestBuffer);
    } else {
      [];
    };
  };

  public shared({ caller }) func getWhiteList() : async [Principal] {
    if (await isAdmin(caller)) {
      Buffer.toArray(whitelistedBuffer);
    } else {
      [];
    };
  };
 ```
 `getAdminList`- checks the `adminBuffer` and returns the admin principals as an array. It returns an empty array is the caller is not the admin
 `getRequestList`- checks the `requestBuffer` and returns the entry principals as an array. It returns an empty array is the caller is not the admin

`getWhiteList`- checks the `whitelistedBuffer` and returns the entry principals as an array. It returns an empty array is the caller is not the admin.
This completes our backend code in motoko. All the code can be found in the [GitHub]() repository.


## Deployment
To deploy our code using the motoko playground IDE, we need to supply a principal that will be the owner of the dapp. For now, we will supply the anonymous principal `2vxsx-fae` as the owner for testing purposes.

Your Candid ui should look like this after deloyment. You can test out the functions and to see how they work.


# Frontend Development
In this section, we are going to develop our frontend for the whitelist Dapp and intergrate it with Internet Computer for authentication.
I have prepared a template we shall use to ease the development and save time.
The project template contains three cansiters. 
- **frontend**- this will hold our frontend code
- **backend**- this will hold our completed motoko code
- **internet identity** -This allows us to use Interent Identity both in development(locally) and in production(mainnet).

On your machine, open the terminal or command line.

- Clone this GitHub project repository locally
```bash
git clone https://github.com/sam-the-tutor/whitelistDapp.git
```
- Navigate to the project folder
```
cd whitelistDapp
```
- Install the dependencies
```
npm install
```
- Start dfx
```
dfx start --clean --background
```
- Deploy the project locally
```
dfx deploy
```
After a successful deployment, load up the link for the frontend canister in your favorite browser. It will prompt you to login in this your Internet Identity account. On successful login, your principal will be displayed. Copy and save it safely. we will use it to set up the owner of our whitelist Dapp.

### Backend canister deployment. 
- Open the project template in the code editor like Vs Code or Sublime text.
- Navigate to the `whitelistDap_backend` folder in a file named main.mo.
- Delete all the sample code.
- Copy the project code from the motoko playground IDE and paste it inside that file. Save the changes.

In the command line, run the following command to deploy the backend canister with the Principal as the owner of the dapp
```
dfx deploy whitelistDapp_backend --argument '(principal "XXX-xxxx-XXX")'
```
Replace the `XXX-xxx-XXX` with the Principal Id that you copied from the frontend page.
On successful deployment, running this command in the command line should return the principal Id that you specified as the owner.
```
dfx canister call whitelistDapp_backend theOwner
```
## Frontend Code development.
Navigate to the `src` folder inside the `whitelistDapp_frontend` which contains two files.
 - index.html- to hold our HTML for the project
 - index.js- to hold the Javacript code for the project

The `index.js` contains the neccesary functions `userLogin` and `handleAuthenticated` that help us to login with Internet Identity  to our project locally and on the mainnet. It also contains the neccessary CSS code for the entire project.


### Frontnd Login

On a successful user login the dapp should determine whether the user is an admin or not. Depending on the result, it should either serve the user page or an admin page. This is done by querying `isAdmin` function from the backend canister and passing in the principal of the logged in user. Only the authenticated user should be able to request for a whitelist spot. 

```js
async function handleAuthenticated() {
  identity = await authClient.getIdentity();
  myPrincipal = await identity._principal.toString();

  authenticatedCanister  = createActor(canisterId, {
       agentOptions:{
            identity,
         },
     });


  if(await authenticatedCanister.isAdmin(Principal.fromText(myPrincipal))){
     displayAdminPage()
   }else{
     displayUserPage()
  }
  
}
````

Adjust the `handleAuthenticated()` function to check if the user is an admin or not and run the correct function in any of the conditions.

### User Page
```js
async function displayUserPage(){

  document.getElementById("whitelistDapp").innerHTML= ""
  const userDiv = document.createElement("div")
  
  userDiv.innerHTML = `
        <div class="row text-center">
        <h1>Whitelist Dapp</h1>
        <h4>User Page</h4>
        <div>
         <h5> Principal :<span id="principalId">loading....</span></h5>
        
          <h5> Status : <span id="statusId">loading....</span></h5>

        <div>
        <button class="btn btn-primrequestBtn" type="submit" >Request Whitelist</button>
        </div>
        </div>
        `
  document.getElementById("whitelistDapp").appendChild(userDiv)
  document.getElementById("principalId").innerText = myPrincipal;
  await checkUserStatus()
}

//check user status
async function checkUserStatus(){

  try{

    const result = await authenticatedCanister.checkStatus();
    document.getElementById("statusId").innerText = result;
  }catch(error){
    alert(error)
  }
}

//request for whitelist
document.getElementById("whitelistDapp").addEventListener("click", async (e)=>{
  if(e.target.className.includes("requestBtn")){

    try{
      const result = await authenticatedCanister.requestWhitelist();

      alert(result);
    }catch(error){
      alert(error);

    }
    await checkUserStatus()
    
  }

})
````
The `displayUserPage()` function returns a page to display the Principal of the user, the status of the whitelist request and a button to request for the whitelist spot. It populates the respective elements with the relevant information.

The `checkUserStatus()` function checks for the whitelist status of the logged in user by calling the `checkStatus()` method on the authenticatedanister.
In case of any errors, we display them to the user.

We add an eventListener on the Request Whitelist button and perform the relevant operation on click, which is to request for a whitelist spot.

### Admin Page
```js
async function displayAdminPage(){

  document.getElementById("whitelistDapp").innerHTML= ""
  const adminDiv = document.createElement("div")
  
  adminDiv.innerHTML = `
        <div class="row text-center">
        <h1>Whitelist Dapp</h1>
        <h4>Admin Dashboard</h4>
      </div>

      <div class="row text-left">
        <h5>Admin Principal : <span id="adminPrincipal"> Admin Principal</span></h5>
        <div class="text-right">
               <input type="text" id="adminPrincipalInput" placeholder="Enter Principal">
             <button class="btn btn-primary  adminPrincipalBtn" type="submit">Add Admin</button>
              </div>
          </div>
      
      <div class="row">
          <div class="col-4">
            Whitelist Request  
            <div class="overflow-auto" id = "requestedId" style="height: 380px;">
                
            </div>
          </div>
          <div class="col-4">
            Whitelisted Accounts
            <div class="overflow-auto" id="whitelistedIds" style="height: 380px;">
            </div>
        </div>
        <div class="col-4">
        
            Admin Accounts
            <div class="overflow-auto" id="adminlistId" style="height: 380px;">
            </div>
          </div>
        
      </div>`
  document.getElementById("whitelistDapp").appendChild(adminDiv)
  document.getElementById("adminPrincipal").innerText= myPrincipal

  await getRequests()
  await getWhitelisted()
  await getAdmins()
 }
````
We perform some DOM mainpulation and add a simple admin page to display:
	- Principal Id of the logged in admin
	- principal ids for evryone that requested to be whitelsited
	- Principals Ids for the whitelisted accounts
	- Principal Ids for the admin accounts

```js
//fetch whitelist requests
async function getRequests(){

  let results = await authenticatedCanister.getRequestList();
  document.getElementById("requestedId").innerHTML = ""
  results.forEach((result)=>{
    const newDiv = document.createElement("div");
    newDiv.className = "card"
    newDiv.innerHTML = `
    <div class="card-body">
      <h5 class="card-title">${result.toString()}</h5>
       <a href="#" class="btn btn-primary WhitelistUser" id="${result.toString()}">Grant</a>
    </div>
    `
  document.getElementById("requestedId").appendChild(newDiv);
  })
}

//get whitelisted accounts
async function getWhitelisted(){

  let results = await authenticatedCanister.getWhiteList();
  document.getElementById("whitelistedIds").innerHTML = ""
  results.forEach((result)=>{
    const newDiv = document.createElement("div");
    newDiv.className = "card"
    newDiv.innerHTML = `
    <div class="card-body">
      <h5 class="card-title">${result.toString()}</h5>
       <a href="#" class="btn btn-primary revokeWhitelist" id="${result.toString()}">Revoke</a>
    </div>
    `
  document.getElementById("whitelistedIds").appendChild(newDiv);
  })
}

//get admin accounts
async function getAdmins(){

  let results = await authenticatedCanister.geAdminList();
  document.getElementById("adminlistId").innerHTML = ""
  results.forEach((result)=>{
    const newDiv = document.createElement("div");
    newDiv.className = "card"
    newDiv.innerHTML = `
    <div class="card-body">
      <h5 class="card-title">${result.toString()}</h5>
       <a href="#" class="btn btn-primary deleteAdmin" id="${result.toString()}">Delete<i class="bi bi-trash align-right" role="button" id=></i></a>
    </div>
    `
  document.getElementById("adminlistId").appendChild(newDiv);
  })
}
````
The `getAdmin()`, `getWhitelisted()`, and `getRequests()` functions fetch the respective results, create the respective HTML elements and display the results on the admin page.
```js
//whitelist a user
document.getElementById("whitelistDapp").addEventListener("click", async (e)=>{
  if(e.target.className.includes("WhitelistUser")){
    const user = Principal.fromText(e.target.id);

    try{
      const result = await authenticatedCanister.whitelistUser(user);

      alert(result);
    }catch(error){
      alert(error);

    }
  }
  await getWhitelisted()
  await getRequests()

})

//delete admin
document.getElementById("whitelistDapp").addEventListener("click", async (e)=>{
  if(e.target.className.includes("deleteAdmin")){
    const user = Principal.fromText(e.target.id);

    try{
      const result = await authenticatedCanister.deleteAdmin(user);

      alert(result);
    }catch(error){
      alert(error);

    }
    await getAdmins()
    
  }

})

//revoke whitelist
document.getElementById("whitelistDapp").addEventListener("click", async (e)=>{
  if(e.target.className.includes("revokeWhitelist")){
    const user = Principal.fromText(e.target.id);

    try{
      const result = await authenticatedCanister.removeWhiteliste(user);

      alert(result);
    }catch(error){
      alert(error);

    }  
  }

  await getWhitelisted()

})
````

We add EventListeners on the respective buttons `Delete`, `Add Admin`, `Grant` , `Revoke` that allow the admin to perform the operations of:
- deleting a fellow admin.
- adding another admin.
- granting whitelist spot to the user.
- revoking the whitelist spot from the user.
This completes the code for the frontend. All the code can be found in this [GitHub]() repository.

## Local deployment.
Run this command from your root project in the command line to re-deploy the frontend canister.
```
dfx deploy whitelistDapp_frontend
```
On successful deployment, open the frontend canister link in the browser
After logging in with your Internet Identity, you should have something similar to this.
At this stage, there is no admin, no whitelist request and therefore no account has been approved for a whitelist spot.

To test the project out, you can create multiple identities on the local computer and then call the requestWhitelist function on the backend canister. Below is a screenshot of how to do it.

Refresh the browser when you are done with the above step and you should have something like this.

Now you have a few accounts that have requested for the whitelist spot. As an owner of the dapp, you have the same priviledges as the admin. You can grant the whitelist requests, revoke them, add and even remove other admin. But other admins wont be able to remove you.

## Deploy the project on the Internet Computer Mainnet.
This section assumes that you have the cycles in the wallet associated with the identity that you are going to use for deployment. If not check this guide on how to get cycles to your wallet.
its time to deploy the project on the mainnet. We will First deploy the backend canister and then followed by the frontend canister.

### Backend canister deployment on the mainnet.
We will need the principal id of our Internet Identity on the mainnet to set it up as the owner of the dapp. ths we will be able to access the admin dashboard. To do so, head over to this [link](https://5ifxv-hqaaa-aaaag-abkaa-cai.ic0.app/), login with your Internet Identity account and your principal Id will be displayed. Copy the Id.

In the terminal run this command to deploy the whitelistDapp_backend canister on the mainnet
```
dfx deploy whitelistDapp_backend --network ic --argument '(principal "YYY-yyy-YYY")'
```
Replace the `YYY-yyy-YYY` with the Principal Id that you copied from the previous step.

### Frontend canister deployment on the mainnet
Run this command in the terminal to deploy the frontend canister on the mainnet.
```
dfx deploy whitelistDapp_frontend --network ic
```
On successful deployment, you should be presented with a link on this format, where `xxxxx-xxxxx-xxxxx-xxxxx` is the id of the frontend canister on the Internet Computer.
```
https://xxxxx-xxxxx-xxxxx-xxxxx-cai.ic0.app
```
Load it in the browser, login with your Internet Identity account and you should be able to access the admin dashboard.
You can send the link to your friends to test out the Dapp. In that case, your friends will be presented with the user page since none of them is an admin. From there, they can request for a whitelist spot and also view the status of their requests.

## Next steps
Right now, our project cannot persist data across upgrades,leave alone the owner variable. Functionality can be added for pre and post upgrade to persist data. 
More changes can be added to the project like adding a notification when a new user requests for a whitelist spot, allowing the user to provide more information aside from their Id among other improvements. learn more about the Internet Identity, Internet Computer and Motoko and how these technologies can used in your next project.

## Conclusion
In this article, you have learnt how, to write motoko code for a whitelist Dapp, developing the front end for the project, Deploying the project both locally and on the Internet Computer and using the internet Identity to facilitate the login and aithentication.
Incase of any inquiries, let's connect on Twitter. I will be glad to help out.








 
