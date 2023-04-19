import { whitelistDapp_backend, canisterId, createActor } from "../../declarations/whitelistDapp_backend";
import {AuthClient} from "@dfinity/auth-client";
import { Principal } from "@dfinity/principal";



let authenticatedCanister = whitelistDapp_backend;

let myPrincipal;

let authClient;

let identity;



async function userLogin(){

  authClient = await AuthClient.create();

  if (await authClient.isAuthenticated()) {
    handleAuthenticated();
  } else {
    await authClient.login({
      identityProvider: process.env.II_URL,
      onSuccess: () => {
        handleAuthenticated();
      },
    });
  }
};

async function handleAuthenticated() {
  identity = await authClient.getIdentity();
  myPrincipal = await identity._principal.toString();

  // console.log("canister Id:",canisterId)
  // console.log("myPrincipal : ",myPrincipal);
  //  console.log("AuthClient : ",authClient);

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



//prompt login when page is loaded
window.addEventListener('load', async ()=>{
  await userLogin()
})








async function displayUserPage(){

  document.getElementById("whitelistDapp").innerHTML= ""
  const userDiv = document.createElement("div")
  
  userDiv.innerHTML = `
        <div class="row text-center">
        <h1>Whitelist Dapp</h1>
        <h4>User Page</h4>
        <div>
         <h5> Principal : <span id="principalId">loading....</span></h5>
        
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
        
      </div>

        `
  document.getElementById("whitelistDapp").appendChild(adminDiv)
  document.getElementById("adminPrincipal").innerText= myPrincipal


  await getRequests()
  await getWhitelisted()
  await getAdmins()



 }


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



//get admin accounts
async function getAdmins(){

  let results = await authenticatedCanister.getAdminList();
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




//add new admin
document.getElementById("whitelistDapp").addEventListener("click", async (e)=>{
  if(e.target.className.includes("adminPrincipalBtn")){
    const user = document.getElementById("adminPrincipalInput").value;

    if(user != ""){
      const _principal = Principal.fromText(user);
      const result = await authenticatedCanister.addAdmin(_principal);
      alert(result);
    }
    
  }
  await getAdmins()

})




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





