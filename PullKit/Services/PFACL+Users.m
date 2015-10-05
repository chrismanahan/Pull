//
//  PFACL+Users.m
//  Pull
//
//  Created by Chris M on 10/5/15.
//  Copyright © 2015 Pull LLC. All rights reserved.
//

#import "PFACL+Users.h"

@implementation PFACL (Users)

+ (PFACL*)ACLWithUser:(PFUser*)user0 and:(PFUser*)user1;
{
    PFACL *acl = [PFACL ACL];
    [acl setPublicReadAccess:NO];
    [acl setReadAccess:YES forUser:user0];
    [acl setWriteAccess:YES forUser:user0];
    [acl setReadAccess:YES forUser:user1];
    [acl setWriteAccess:YES forUser:user1];
    
    return acl;
}

@end
