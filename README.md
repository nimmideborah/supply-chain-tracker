# Supply Chain Tracker

An end-to-end supply chain transparency platform that tracks products from manufacturing to consumer delivery. Enables manufacturers, distributors, and retailers to record product journeys, verify authenticity, and provide consumers with complete product histories including sustainability metrics.

## 🌟 Features

- **End-to-End Tracking**: Complete product journey from manufacturing to consumer
- **Product Registry**: Unique identifier system with immutable product records
- **Authenticity Verification**: Cryptographic proofs of product authenticity
- **Supply Chain Participants**: Multi-party ecosystem with role-based permissions
- **Sustainability Metrics**: Environmental impact tracking and reporting
- **Batch Management**: Efficient handling of product batches and lots
- **Compliance Verification**: Industry standard validation and certification
- **Consumer Transparency**: Complete product history access for end users

## 🏗️ Architecture

The system consists of two main smart contracts:

### Product Registry Contract (`product-registry.clar`)
- Manages product creation and registration with unique identifiers
- Stores manufacturing details and sustainability metrics
- Handles ownership transfers between supply chain participants
- Maintains immutable product histories with batch tracking
- Manages product lifecycle states and transitions
- Provides product authenticity verification mechanisms

### Chain Verifier Contract (`chain-verifier.clar`)
- Validates supply chain transitions and custody changes
- Verifies participant credentials and certifications
- Enforces compliance with industry standards
- Generates authenticity proofs for consumers and auditors
- Maintains audit trails for regulatory compliance
- Handles dispute resolution and verification challenges

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) v1.0+
- [Node.js](https://nodejs.org/) v16+
- [Git](https://git-scm.com/)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/nimmideborah/supply-chain-tracker.git
cd supply-chain-tracker
```

2. Install dependencies:
```bash
npm install
```

3. Check contract syntax:
```bash
clarinet check
```

4. Run tests:
```bash
npm test
```

### Local Development

Start a local development environment:

```bash
clarinet console
```

Deploy contracts to devnet:
```bash
clarinet deployments apply --devnet
```

## 📋 Smart Contract Functions

### Product Registry

#### Public Functions
- `create-product(name, description, manufacturer, batch-id)` - Register new products
- `transfer-ownership(product-id, new-owner)` - Transfer product custody
- `update-location(product-id, location, timestamp)` - Update product location
- `add-sustainability-metric(product-id, metric-type, value)` - Add environmental data
- `update-product-status(product-id, new-status)` - Update product lifecycle status

#### Read-Only Functions
- `get-product-info(product-id)` - Retrieve complete product information
- `get-product-history(product-id)` - Get full product journey
- `get-current-owner(product-id)` - Check current product owner
- `verify-product-authenticity(product-id)` - Validate product authenticity

### Chain Verifier

#### Public Functions
- `register-participant(participant-address, role, certifications)` - Register supply chain participants
- `verify-transfer(product-id, from-participant, to-participant)` - Validate ownership transfers
- `submit-compliance-proof(product-id, standard, proof-hash)` - Submit compliance evidence
- `challenge-verification(product-id, challenger, reason)` - Initiate verification challenge
- `resolve-dispute(dispute-id, resolution)` - Resolve verification disputes

#### Read-Only Functions
- `get-participant-info(participant-address)` - Get participant details and certifications
- `verify-compliance(product-id, standard)` - Check compliance status
- `get-transfer-history(product-id)` - Get all ownership transfers
- `is-participant-certified(participant-address, certification)` - Verify certifications

## 🔒 Security Features

- **Immutable Records**: All product data is permanently recorded on-chain
- **Cryptographic Verification**: Digital signatures for all transactions
- **Role-Based Access Control**: Different permissions for different participant types
- **Multi-Party Validation**: Consensus mechanisms for critical operations
- **Audit Trails**: Complete logging of all supply chain events
- **Dispute Resolution**: Built-in mechanisms for handling verification challenges

## 🌍 Supply Chain Participants

### Manufacturers
- Product creation and initial registration
- Sustainability metrics recording
- Quality certifications and standards compliance
- Batch and lot management

### Distributors
- Custody transfers and logistics tracking
- Warehouse and transportation updates
- Compliance verification and reporting
- Inventory management integration

### Retailers
- Final mile tracking and consumer delivery
- Point-of-sale integration
- Customer verification services
- Return and warranty management

### Consumers
- Product authenticity verification
- Complete product history access
- Sustainability impact information
- Authenticity certificate generation

### Auditors & Regulators
- Compliance monitoring and verification
- Audit trail analysis and reporting
- Industry standard enforcement
- Regulatory compliance validation

## 🧪 Testing

Run the comprehensive test suite:

```bash
# Run all tests
npm test

# Run specific test files
npm test -- product-registry.test.ts
npm test -- chain-verifier.test.ts

# Run tests with coverage
npm run test:coverage
```

## 🌐 Deployment

### Testnet Deployment

1. Update your deployment configuration in `settings/Testnet.toml`
2. Deploy to testnet:
```bash
clarinet deployments apply --testnet
```

### Mainnet Deployment

1. Update your deployment configuration in `settings/Mainnet.toml`
2. Deploy to mainnet:
```bash
clarinet deployments apply --mainnet
```

## 📖 Usage Examples

### Creating a Product

```clarity
(contract-call? .product-registry create-product 
  u"Organic Coffee Beans" 
  u"Single-origin Ethiopian coffee, fair trade certified" 
  'SP1MANUFACTURER... 
  u\"BATCH-2024-001\")
```

### Transferring Ownership

```clarity
(contract-call? .product-registry transfer-ownership 
  u1 ;; product-id
  'SP1DISTRIBUTOR...) ;; new owner
```

### Verifying Transfer

```clarity
(contract-call? .chain-verifier verify-transfer 
  u1 ;; product-id
  'SP1MANUFACTURER... ;; from
  'SP1DISTRIBUTOR...) ;; to
```

### Adding Sustainability Metrics

```clarity
(contract-call? .product-registry add-sustainability-metric 
  u1 ;; product-id
  u\"carbon-footprint\" 
  u150) ;; kg CO2
```

## 🏭 Industry Applications

### Food & Agriculture
- Farm-to-table tracking
- Organic certification verification
- Food safety compliance
- Harvest and processing records

### Pharmaceuticals
- Drug authenticity verification
- Temperature chain monitoring
- Batch recall management
- Regulatory compliance tracking

### Luxury Goods
- Anti-counterfeiting measures
- Authenticity certificates
- Provenance verification
- Resale value protection

### Electronics
- Component sourcing verification
- Conflict mineral compliance
- Recycling and disposal tracking
- Warranty and repair history

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Clarity](https://clarity-lang.org/) smart contract language
- Powered by [Stacks](https://stacks.co/) blockchain
- Development tooling by [Clarinet](https://github.com/hirosystems/clarinet)

## 📞 Support

- GitHub Issues: [Create an issue](https://github.com/nimmideborah/supply-chain-tracker/issues)
- Documentation: [Clarity Language Reference](https://docs.stacks.co/clarity)
- Community: [Stacks Discord](https://discord.gg/stacks)

---

**⚠️ Security Notice**: This project is for educational and development purposes. Always conduct thorough security audits before deploying to mainnet with real value.