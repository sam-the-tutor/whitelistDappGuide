import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import HashMap "mo:base/HashMap";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";


//declare an actor for the whitelist dapp.
//Declare the dapp owner on deployment
actor class whitelistDapp(dappOwner : Principal) = {

  //store the owner of the dapp
  stable let owner : Principal = dappOwner;

  //declare buffer storage for whitelist requests
  let requestBuffer = Buffer.Buffer<Principal>(20);

  //declare buffer storage for whitelisted accounts
  let whitelistedBuffer = Buffer.Buffer<Principal>(20);

  //declare buffer storage for admin accounts
  let adminBuffer = Buffer.Buffer<Principal>(20);

  //user requests to be whitelisted
  public shared({ caller }) func requestWhitelist() : async Text {
    if (Buffer.contains<Principal>(requestBuffer, caller, Principal.equal)) {
      "You have already requested for a whitelist";
    } else if (Buffer.contains<Principal>(whitelistedBuffer, caller, Principal.equal)) {
      return "You are already whitelisted"
    } else {
      requestBuffer.add(caller);
      return "Request accepted. Waiting for admin confirmation";

    };
  };

  //add admin by another admin or owner
  public shared({ caller }) func addAdmin(newAdmin : Principal) : async Text {

    if (await isAdmin(caller)) {
      if (not Buffer.contains<Principal>(adminBuffer, newAdmin, Principal.equal)) {
        //assert (not Buffer.contains<Principal>(adminBuffer, newAdmin, Principal.equal));
        adminBuffer.add(newAdmin);
        "Admin added successfully";
      } else {
        "User already admin";
      }

    } else {
      "You are not approved to add admins";
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
      "You are not approved to delete admins";
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

      for (entry in requestBuffer.vals()) {
        if (entry == user) {
          let entryIndex = Buffer.indexOf<Principal>(
            entry,
            requestBuffer,
            Principal.equal,
          );
          switch (entryIndex) {
            case (?index) {
              whitelistedBuffer.add(user);
              ignore requestBuffer.remove(index);
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

  //Remove whitelist from the user
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
              resultText := "Whitelist revoked successfully";
            };
            case (null) {
              resultText := "User does not exist";
            };
          };

        };
      };
      return resultText;

    } else {
      "You are not approved to revoke whitelists";
    }

  };

  //get all admin IDs
  public shared({ caller }) func getAdminList() : async [Principal] {
    if (await isAdmin(caller)) {
      Buffer.toArray(adminBuffer);
    } else {
      [];
    };
  };

  //get all IDs requesting for whitelist
  public shared({ caller }) func getRequestList() : async [Principal] {
    if (await isAdmin(caller)) {
      Buffer.toArray(requestBuffer);
    } else {
      [];
    };
  };

  //get all whitelisted IDs
  public shared({ caller }) func getWhiteList() : async [Principal] {
    if (await isAdmin(caller)) {
      Buffer.toArray(whitelistedBuffer);
    } else {
      [];
    };
  };

  //check status of the whitelist
  public shared({ caller }) func checkStatus() : async Text {
    if ((Buffer.contains<Principal>(requestBuffer, caller, Principal.equal))) {
      return "Waiting for admin confirmation.";
    } else if ((Buffer.contains<Principal>(whitelistedBuffer, caller, Principal.equal))) {
      return "Congratulations. You are whitelisted"

    } else {
      return "Status unknown. Please request for the whitelist spot";
    };
  };

  // Return the principal of the dapp owner
  public func theOwner() : async Principal {
    return owner;
  };

};




