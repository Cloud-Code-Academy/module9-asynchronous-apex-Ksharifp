/*
 * NextStepFuture Class Description:
 * 
 * Question 1: Create a future method that updates all account and opportunities next step to 'Meeting in the future'
 * Question 2: Create a method that inserts a big deal opportunity and updates the user role name to 'CRO'
 * 
 * Benefits of using future methods:
 * 
 * 1. Asynchronous Processing: Allows long-running operations to be handled in the background, freeing up resources.
 * 2. Governor Limit Management: Asynchronous methods have a separate set of limits, providing more flexibility.
 * 3. User Experience Enhancement: Improves responsiveness in user interfaces by offloading processes to the background.
 * 4. Mixed DML Operations Handling: Helps overcome Mixed DML errors by allowing updates on setup and non-setup objects.
 * 5. Enhanced Integration Capabilities: Useful for making callouts to external systems without blocking the user interaction.
 * 
 * For more detailed information, refer to the official Salesforce documentation: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_invoking_future_methods.htm
 * 
 * Note: The class below contains placeholders for implementing a future method to update accounts and opportunities.
 *       The accompanying test class 'AsynchronousTest' should also be updated to test this method.
 */
public with sharing class NextStepFuture {

    /* 
     * Question 1
     * Update/Uncomment the template code to create a method
     * Create a future method that updates all account and opportunities next step to 'Meeting in the future'
     * Account Next Step field is a custom field
     * Opportunity Next Step field is a standard field
     * Update the corresponding test class AsynchronousTest and test method nextStepFuture_testUpdateAllNextStep to cover test this method
     */
    @future
    public static void accNextStepFuture () {
    //  The body of the method
        //declaring a string variable for the next step message
        String NextStepMessage = 'Meeting in the future';

        //get all the account records along with their child opportunities
        List<Account> allAccounts = [SELECT Id, Next_Step__c, (SELECT Id, NextStep FROM Opportunities) FROM Account];

        //a list to add the related opportunities into
        List<Opportunity> opps = new List<Opportunity>();

        //going through all accounts and update their Next Step field
        for (Account a : allAccounts) {
            a.Next_Step__c = NextStepMessage;
            opps.add(a.Opportunities);
        }
        update allAccounts;
        
        //going through all related opportunities and update their Next Step field
        for (Opportunity opp : opps) {
            opp.NextStep = NextStepMessage;
        }
        update Opps;
    }

    /*
    * Question 2
    * Update/Uncomment the template code to create a method
    * Create a method that inserts a big deal opportunity and updates the user role name to 'CRO'
    * Update the corresponding test class AsynchronousTest and test method nextStepFuture_testCreateDealAndUpdateRole to cover test this method
    */
    //Mix DML Error happens when you try to perform DML operations on setup and non-setup objects in a single transaction.
    
    public static void createDealAndUpdateRole() {
        
        insertBigDeal(1000000, 'Big Deal', 'Closed Won');

        UserRole[] roles = [SELECT Id, Name FROM UserRole WHERE Id = :UserInfo.getUserRoleId() OR Name = 'CRO' LIMIT 1];
        List<Id> userRoleIds = new List<Id>();
        for (UserRole ur : roles) {
            userRoleIds.add(ur.Id);
        }

        updateUserRoleName(userRoleIds);
    }

    // Helper method to insert big deal
    private static void insertBigDeal(Decimal amount, String name, String stage) {
        Opportunity bigDeal = new Opportunity();
        bigDeal.Amount = amount;
        bigDeal.Name = name;
        bigDeal.StageName = stage; 
        bigDeal.CloseDate = Date.today();
        
        insert bigDeal;
    }

    @future
    // Helper method to update role name
    private static void updateUserRoleName(List<Id> userRoleIds){
        UserRole role;
        if (userRoleIds.isEmpty()) {
            role = new UserRole();
            role.portalType = 'None'; 
            role.CaseAccessForAccountOwner = 'Edit'; 
            // role.OpportunityAccessForAccountOwner = 'Edit'; //This may need to be uncommented depending on your orgs Organization Wide Defaults(OWD) settings. If you are receiving FIELD_INTEGRITY_EXCEPTION, field integrity exception: unknown (Opportunity access level below organization default): [unknown], uncomment this line.
        } else {
            role.Id = userRoleIds[0];
        }

        role.Name = 'CRO';

        upsert role;
    }
}