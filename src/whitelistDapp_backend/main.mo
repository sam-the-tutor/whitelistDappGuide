import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import HashMap "mo:base/HashMap";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";

//declare an actor for the whitlist dapp.
//whoever deploys it insiide will be the owner
actor class whitelistDapp(dappOwner : Principal) = {

  //store the owner of the dapp
  var owner : Principal = dappOwner;

  //declare buffer storage for whitelist requests
  let requestBuffer = Buffer.Buffer<Principal>(20);

  //declare buffer storage for whitelisted accounts
  let whitelistedBuffer = Buffer.Buffer<Principal>(20);

  //declare buffer storage for whitelist requests
  let adminBuffer = Buffer.Buffer<Principal>(20);

  //user requests to be whitelisted
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
      "you are not aproved to revoke whitelists";
    }

  };

  //get all admins
  public shared({ caller }) func getAdminList() : async [Principal] {
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

  //get all requests
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

  // Return the principal identifier of the caller of this method.
  public func theOwner() : async Principal {
    return owner;
  };

};
