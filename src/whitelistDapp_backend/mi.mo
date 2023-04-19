import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import HashMap "mo:base/HashMap";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";

//declare an actor for the whitlist dapp.
//whoever deploys it insiide will be the owner
actor class whitelistDapp(dappOwnerdappOwner : Principal) = {

  //declare buffer storage for whitelist requests
  let requestBuffer = Buffer.Buffer<Principal>(20);

  //store the owner of the dapp
  stable let owner : Principal = dappOwnerdappOwner;

  //declare a hashmap to add users to the whitelist
  let whitelistedUsers = HashMap.HashMap<Principal, Bool>(
    1,
    Principal.equal,
    Principal.hash,
  );

  //declare buffer storage for whitelist requests
  let adminBuffer = Buffer.Buffer<Principal>(20);

  //user requests to be whitelisted
  public shared({ caller }) func requestWhitelist() : async Text {
    if (Buffer.contains<Principal>(requestBuffer, caller, Principal.equal)) {
      "you have already requested for a whitelist";
    } else {
      switch (whitelistedUsers.get(caller)) {
        case (?true) {
          return "User already whitelisted";
        };
        case (?false or null) {
          requestBuffer.add(caller);
          return "Request accepted. Waiting for admin confirmation";
        };
      };

    };
  };

  //add admin by another admin or owner
  public shared({ caller }) func addAdmin(newAdmin : Principal) : async Text {

    if (await isAdmin(caller)) {
      if (not Buffer.contains<Principal>(adminBuffer, newAdmin, Principal.equal)) {
        //assert (not Buffer.contains<Principal>(adminBuffer, newAdmin, Principal.equal));
        adminBuffer.add(newAdmin);
        "admin added successfully";
      } else {
        "User already admin";
      }

    } else {
      "you are not aproved to add admins";
    }

  };

  //delete admin
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
              resultText := "admin deleted successfully";
            };
            case (null) {
              resultText := "Admin does not exist";
            };
          };

        };
      };
      return resultText;

    } else {
      "you are not aproved to delete admins";
    }

  };

  //check for admin
  public func isAdmin(p : Principal) : async Bool {
    if ((p == owner)) {
      return true;
    } else if ((Buffer.contains<Principal>(adminBuffer, p, Principal.equal))) {
      return true;
    } else {
      return false;
    }

  };

  //whitelist user
  public shared({ caller }) func whitelistUser(user : Principal) : async Text {
    var resultText : Text = "";
    if (await isAdmin(caller)) {
      whitelistedUsers.put(user, true);

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
              resultText := "user whitelisted successfully";
            };
            case (null) {
              resultText := "request does not exist";
            };
          };

        };
      };
      return resultText;

    } else {
      "you are not aproved to whitelist users";
    }

  };

  //dewhitelist a user
  public shared({ caller }) func removeWhiteliste(user : Principal) : async Text {
    if (await isAdmin(caller)) {

      whitelistedUsers.delete(user);
      "user de-whitelisted successfully"

    } else {
      "you are not aproved to whitelist users";
    }

  };

  //get all admins
  public shared({ caller }) func geAdminList() : async [Principal] {
    if (await isAdmin(caller)) {
      Buffer.toArray(adminBuffer);
    } else {
      [];
    };
  };

  //get all requests
  public shared({ caller }) func getRequestList() : async [Principal] {
    if (await isAdmin(caller)) {
      Buffer.toArray(requestBuffer);
    } else {
      [];
    };
  };


  //check status of the whitelist
  public shared({caller}) func checkStatus() : async Text{
    if((Buffer.contains<Principal>(adminBuffer, caller, Principal.equal))){
      return "Waiting for admin confirmation.";
    }else{
      switch(whitelistedUsers.get(caller)) {
        case(null) { 
          return "Unknow. Please request for whitelist";
         };
        case(?entry) {
          "Congratulations. You are whitelisted";
         };
      };
    }
  };

  // Return the principal identifier of the caller of this method.
  public shared(msg) func whoami() : async Principal {
    return owner;
  };

};
