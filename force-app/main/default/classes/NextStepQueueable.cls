/*
 * NextStepQueueable Class Description:
 * 
 * Implement the Queueable interface to process records asynchronously.
 * This example processes up to 10 accounts at a time.
 * It removes the Next Step from the accounts and related opportunities.
 *  
 * Benefits of using Queueable methods:
 * 
 * 1. Chaining Jobs: Allows for the chaining of jobs, meaning you can add another job to the queue from a running job.
 * 2. Stateful Execution: Supports stateful execution, which allows member variables to retain their values between job invocations.
 * 3. High Concurrency: Processes large sets of data without hitting governor limits.
 * 4. Flexibility: Useful for operations that need more flexibility in execution, especially when there's a possibility of chaining or performing related async operations.
 * 5. Enhanced Integration Capabilities: Useful for making asynchronous callouts to external systems, allowing for more extended processing times.
 * 
 * For more detailed information, refer to the official Salesforce documentation: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_queueing_jobs.htm
 * 
 * Note: The class below contains placeholders for implementing a queueable job to update accounts and opportunities.
 */
public with sharing class NextStepQueueable implements Queueable{

    // Member variable to store the accounts
    private Map<Id,Account> accounts;

    // Constructor to accept the accounts
    public NextStepQueueable(Map<Id,Account> accounts) {
        // Store the accounts in a member variable
        this.accounts = accounts;
    }

    // Method to queue the job
    public static void enqueueJob() {
        // Get 10 accounts with Next Step populated
        List<Account> accountsWithNextStep = [
            SELECT Id, Next_Step__c 
            FROM Account 
            WHERE Next_Step__c != null ORDER BY Name LIMIT 10];

        // If there are any accounts, queue the job using System.enqueueJob
        if (!accountsWithNextStep.isEmpty()) {
              ID jobID = System.enqueueJob(new NextStepQueueable(new Map<Id, Account>(accountsWithNextStep)));
        }
    }
        
        
    /*
     * Update/Uncomment the template code to create a method
     * Method to execute the queueable job
     */
    public void execute (QueueableContext context) {
        // Get the accounts from the member variable
        List<Account> accountsToUpdate = new List<Account>();
        for (Id accountId : accounts.keySet()) {
            // Remove the Next Step using the helper method
            NextStepQueueable.removeNextStepAcc(accounts.get(accountId));
            accountsToUpdate.add(accounts.get(accountId));
        }
        // Update the accounts
         if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
            
        // Get the opportunities related to the accounts
        List<Opportunity> opportunities = [
            SELECT Id, AccountID, NextStep 
            FROM Opportunity 
            WHERE AccountId IN : accounts.keySet() AND NextStep != null];
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
            // Remove the Next Step using the helper method
        for (Opportunity opportunityToUpdate : opportunities) {
            Opportunity newOpp = new Opportunity(Id=opportunityToUpdate.Id);
            NextStepQueueable.removeNextStepOpp(newOpp);
            oppsToUpdate.add(newOpp);
        }
        // Update the opportunities
        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }
        // Call the enqueueJob method to queue another job to process more records.
        // System.enqueueJob(new NextStepQueueable(accounts));
    

        // Check if there are more accounts to process before queueing another job
        List<Account> moreAccountsWithNextStep = [
            SELECT Id 
            FROM Account 
            WHERE Next_Step__c != null 
            LIMIT 1
        ];
        
        // Only queue another job if there are more records to process
        if (!moreAccountsWithNextStep.isEmpty()) {
            enqueueJob(); // Call the static method to queue the next batch
        }
    }

    // Helper method to remove the Next Step
    // Overloaded method to accept an opportunity
    private static void removeNextStepOpp(Opportunity opp) {
        opp.NextStep = null;
    }

    // Helper method to remove the Next Step
    // Overloaded method to accept an account
    private static void removeNextStepAcc(Account acc) {
        acc.Next_Step__c = null;
    }
}