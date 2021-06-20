public class Attachment2FileBatch implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Name,Body,ParentId FROM Attachment WHERE CreatedDate = today');
    }
    public void execute(Database.BatchableContext bc, List<Attachment> attList){
        // Create contentVersion for each attachment
        List<ContentVersion> cvList = new List<ContentVersion>();
        Map<Id,Attachment> attMap = new Map<Id,Attachment>();
        for (Attachment att : attList) {
        	ContentVersion cv = new ContentVersion();
            cv.Title = att.Name;
            cv.PathOnClient = att.Name;
            cv.VersionData = att.Body;
            cvList.add(cv);
            attMap.put(att.id,att);
        }
        insert cvList;
        
        //Link ContentVersion id with respective Attachment Id
        Map<Id,Id> atCvIdMap = new Map<Id,Id>();
        for (Integer i=0; i < cvList.size(); i++) {
        	atCvIdMap.put(cvList[i].id,attList[i].Id);
        }
        
        //Retrive ContentDocumentId
        Map<Id,ContentVersion> cvMap = new Map<Id,ContentVersion>([SELECT ContentDocumentId FROM ContentVersion 
                                                                   WHERE Id = :cvList]);
        
        //Create ContentDocumentLink for each ContentVersion
        List<ContentDocumentLink> cdLinkList = new List<ContentDocumentLink>();
        for(ContentVersion cv : cvMap.values()){
        	ContentDocumentLink cdLink = new ContentDocumentLink();
            cdLink.ContentDocumentId = cv.ContentDocumentId;
            //Link the attachment ParentId to LinkedEntityId
            cdLink.LinkedEntityId = attMap.get(atCvIdMap.get(cv.id)).ParentId;
            cdLink.ShareType = 'I';
            cdLinkList.add(cdLink);
        }
        insert cdLinkList;
        
        //Delete legacy attachment records
        delete attList;
        
    }
    public void finish(Database.BatchableContext bc){
        // execute any post-processing operations
        System.debug('Batch Job Processing Completed');
    }
}