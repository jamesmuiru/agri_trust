# blockchain_services.py
import hashlib
import uuid
from datetime import datetime

class BlockchainService:
    @staticmethod
    def create_smart_contract(order):
        """
        Simulate smart contract creation for escrow
        """
        contract_data = {
            'order_id': str(order.id),
            'buyer': order.buyer.username,
            'farmer': order.produce.farmer.username,
            'amount': str(order.total_price),
            'timestamp': datetime.now().isoformat(),
        }
        
        # Create a simulated transaction hash
        contract_string = ''.join([str(v) for v in contract_data.values()])
        tx_hash = hashlib.sha256(contract_string.encode()).hexdigest()
        
        return f"0x{tx_hash[:64]}"
    
    @staticmethod
    def release_escrow(order):
        """
        Simulate escrow release on delivery confirmation
        """
        if order.status == 'delivered' and not order.escrow_released:
            # Simulate blockchain transaction for payment release
            release_data = {
                'original_tx': order.blockchain_tx_hash,
                'release_timestamp': datetime.now().isoformat(),
                'status': 'released'
            }
            
            release_string = ''.join([str(v) for v in release_data.values()])
            release_hash = hashlib.sha256(release_string.encode()).hexdigest()
            
            return f"0x{release_hash[:64]}"
        
        return None