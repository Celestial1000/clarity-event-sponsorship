import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create new event",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('event-sponsorship', 'create-event', [
                types.ascii("Test Event"),
                types.uint(1000),
                types.uint(100)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(0);
    }
});

Clarinet.test({
    name: "Can sponsor an event",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        // First create an event
        let block1 = chain.mineBlock([
            Tx.contractCall('event-sponsorship', 'create-event', [
                types.ascii("Test Event"),
                types.uint(1000),
                types.uint(100)
            ], deployer.address)
        ]);
        
        // Then sponsor it
        let block2 = chain.mineBlock([
            Tx.contractCall('event-sponsorship', 'sponsor-event', [
                types.uint(0),
                types.uint(500)
            ], wallet1.address)
        ]);
        
        block2.receipts[0].result.expectOk().expectBool(true);
        
        // Check sponsorship amount
        let block3 = chain.mineBlock([
            Tx.contractCall('event-sponsorship', 'get-sponsorship-amount', [
                types.uint(0),
                types.principal(wallet1.address)
            ], deployer.address)
        ]);
        
        block3.receipts[0].result.expectOk().expectUint(500);
    }
});
