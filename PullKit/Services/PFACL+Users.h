//
//  PFACL+Users.h
//  Pull
//
//  Created by Chris M on 10/5/15.
//  Copyright © 2015 Pull LLC. All rights reserved.
//

#import "PFACL.h"

@interface PFACL (Users)

/**
 *  Creates an ACL that is readable and writable to a pair of users and no public access
 *
 *  @param user0 First user
 *  @param user1 Second user
 *
 *  @return ACL 
 */
+ (PFACL*)ACLWithUser:(PFUser*)user0 and:(PFUser*)user1;

@end
