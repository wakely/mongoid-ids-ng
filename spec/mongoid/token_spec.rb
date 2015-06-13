require 'spec_helper'

describe Mongoid::Ids do
  let(:document_class) do
    Object.send(:remove_const, :Document) if Object.const_defined?(:Document)
    class Document
      include Mongoid::Document
      include Mongoid::Ids
    end
    Class.new(Document)
  end

  let(:document) do
    document_class.create
  end

  describe '#token' do
    describe 'default "_id"' do

      before(:each) { document_class.send(:token) }

      it 'should be created' do
        expect(document).to have_field(:_id)
      end

      it 'should be valid' do
        expect(document).to be_valid
      end

      it 'should be persisted' do
        document.save
        # why the anonymous #document_class doesn't work?
        expect(Document.count).to eq(1)
      end

      it 'should not create any secondary index' do
        expect(document.index_specifications).to be_empty
      end
    end

    describe 'field "token"' do
      before(:each) { document_class.send(:token, :token) }
      it 'should be created' do
        expect(document).to have_field(:token)
      end

      it 'should be indexed' do
        index = document.index_specifications.first
        expect(index.fields).to eq([:token])
        expect(index.options).to have_key(:unique)
        expect(index.options).to have_key(:sparse)
      end
    end

    describe 'options' do
      it 'should accept custom field names' do
        document_class.send(:token, :smells_as_sweet)
        expect(document).to have_field(:smells_as_sweet)
      end

      it 'should accept custom lengths' do
        document_class.send(:token, :length => 13)
        expect(document.id.length).to eq 13
      end

      it 'should accept custom lengths on custom fields' do
        document_class.send(:token, :sweet, :length => 13)
        expect(document.sweet.length).to eq 13
      end

      it 'should not create any custom finder' do
        class UntaintedDocument
          include Mongoid::Document
          include Mongoid::Ids
        end
        dc = Class.new(UntaintedDocument)

        dc.send(:token, :skip_finders => true)
        expect(dc.public_methods).to_not include(:find_with_id)
      end

      it 'should not create custom finders with default id' do
        class UntaintedDocument
          include Mongoid::Document
          include Mongoid::Ids
        end
        dc = Class.new(UntaintedDocument)

        dc.send(:token)
        expect(dc.public_methods).to_not include(:find_with_id)
      end

      it 'should disable custom finders with optional field' do
        class UntaintedDocument
          include Mongoid::Document
          include Mongoid::Ids
        end
        dc = Class.new(UntaintedDocument)

        dc.send(:token, :token, skip_finders: true)
        expect(dc.public_methods).to_not include(:find_with_token)
      end

      it 'should not change `to_param`' do
        document_class.send(:token, override_to_param: false)
        expect(document.to_param).to eq document.id
      end

      it 'should disable `to_param` overrides' do
        document_class.send(:token, :token, override_to_param: false)
        expect(document.to_param).to_not eq document.token
      end

      it 'should return id when token does not exist when calling `to_param`' do
        document_class.send(:token, :token, override_to_param: true)
        document.unset :token
        expect(document.to_param).to eq document.id.to_s
      end

      describe 'contains' do
        context 'with :alphanumeric' do
          it 'should contain only letters and numbers' do
            document_class.send(:token, contains: :alphanumeric, length: 64)
            expect(document.id).to match(/[A-Za-z0-9]{64}/)
          end

          it 'should contain only letters and numbers on custom field' do
            document_class.send(:token, :token, :contains => :alphanumeric, :length => 64)
            expect(document.token).to match(/[A-Za-z0-9]{64}/)
          end
        end

        context 'with :alpha' do
          it 'should contain only letters' do
            document_class.send(:token, contains: :alpha, length: 64)
            expect(document.id).to match(/[A-Za-z]{64}/)
          end

          it 'should contain only letters on custom fields' do
            document_class.send(:token, :token, contains: :alpha, length: 64)
            expect(document.token).to match(/[A-Za-z]{64}/)
          end
        end

        context 'with :alpha_upper' do
          it 'should contain only uppercase letters' do
            document_class.send(:token, contains: :alpha_upper, length: 64)
            expect(document.id).to match(/[A-Z]{64}/)
          end

          it 'should contain only uppercase letters on custom fields' do
            document_class.send(:token, :token, contains: :alpha_upper, length: 64)
            expect(document.token).to match(/[A-Z]{64}/)
          end
        end

        context "with :alpha_lower" do
          it "should contain only lowercase letters" do
            document_class.send(:token, :token, contains: :alpha_lower, length: 64)
            expect(document.token).to match(/[a-z]{64}/)
          end
        end

        context 'with :numeric' do
          it 'should only contain numbers' do
            document_class.send(:token, :token, :contains => :numeric, :length => 64)
            expect(document.token).to match(/[0-9]{1,64}/)
          end
        end

        context 'with :fixed_numeric' do
          it 'should contain only numbers and be a fixed-length' do
            document_class.send(:token, :token, :contains => :fixed_numeric, :length => 64)
            expect(document.token).to match(/[0-9]{64}/)
          end
        end

        context 'with :fixed_numeric_no_leading_zeros' do
          it 'should contain only numbers, be a fixed length, and have no leading zeros' do
            document_class.send(:token, :token, :contains => :fixed_numeric_no_leading_zeros, :length => 64)
            expect(document.token).to match(/[1-9]{1}[0-9]{63}/)
          end
        end
      end

      describe 'pattern' do
        it 'should conform' do
          document_class.send(:token, :token, :pattern => '%d%d%d%d%C%C%C%C')
          expect(document.token).to match(/[0-9]{4}[A-Z]{4}/)
        end
        context 'when there\'s a static prefix' do
          it 'should start with the prefix' do
            document_class.send(:token, :token, :pattern => 'PREFIX-%d%d%d%d')
            expect(document.token).to match(/PREFIX\-[0-9]{4}/)
          end
        end
        context 'when there\'s an infix' do
          it 'should contain the infix' do
            document_class.send(:token, :token, :pattern => '%d%d%d%d-INFIX-%d%d%d%d')
            expect(document.token).to match(/[0-9]{4}\-INFIX\-[0-9]{4}/)
          end
        end
        context 'when there\'s a suffix' do
          it 'should end with the suffix' do
            document_class.send(:token, :token, :pattern => '%d%d%d%d-SUFFIX')
            expect(document.token).to match(/[0-9]{4}\-SUFFIX/)
          end
        end
      end
    end

    it 'should allow for multiple tokens of different names' do
      document_class.send(:token, :token, :contains => :alpha_upper)
      document_class.send(:token, :sharing_id, :contains => :alpha_lower)
      expect(document.token).to match(/[A-Z]{4}/)
      expect(document.sharing_id).to match(/[a-z]{4}/)
    end
  end

  describe 'callbacks' do
    context 'when the document is a new record' do
      let(:document){ document_class.new }
      it 'should create the token after being saved' do
        document_class.send(:token, :token)
        expect(document.token).to be_nil
        document.save
        expect(document.token).to_not be_nil
      end
    end

    context 'when the document is not a new record' do
      it 'should not change the token after being saved' do
        document_class.send(:token, :token)
        token_before = document.token
        document.save
        expect(document.token).to eq token_before
      end
      context 'and the token is nil' do
        it 'should create a new token after being saved' do
          document_class.send(:token, :token)
          token_before = document.token
          document.token = nil
          document.save
          expect(document.token).to_not be_nil
          expect(document.token).to_not eq token_before
        end
      end
      context 'when the document is initialized with a token' do
        it 'should not change the token after being saved' do
          document_class.send(:token, :token)
          token = 'test token'
          expect(document_class.create!(token: token).token).to eq token
        end
      end
    end
    context 'when the document is cloned' do
      it 'should set the token to nil' do
        document.class.send(:token, :token, length: 64, contains: :alpha_upper)
        d2 = document.clone
        expect(d2.token).to be_nil
      end

      it 'should generate a new token with the same options as the source document' do
        document.class.send(:token, :token, length: 64, contains: :alpha_upper)
        d2 = document.clone
        d2.save
        expect(d2.token).to_not eq document.token
        expect(d2.token).to match(/[A-Z]{64}/)
      end
    end
  end

  describe 'finders' do
    it 'should not create a custom find method for id' do
      document_class.send(:token)
      expect(document.class.public_methods).to_not include(:find_by_id)
    end

    it 'should create a custom find method' do
      document_class.send(:token, field_name: :other_token)
      expect(document.class.public_methods).to include(:find_by_other_token)
    end
  end

  describe '.to_param' do
    it 'should be removed from this gem' do
      document_class.send(:token, :token)
      expect(document.to_param).to eq document.id.to_s # why to_s?
    end
  end

  describe 'collision resolution on id field' do
    before(:each) do
      document_class.send(:token)
      document_class.create_indexes
    end

    context 'when creating a new record' do
      it 'should raise an exception when collisions can\'t be resolved on save' do
        allow_any_instance_of(document_class).to receive(:generate_token).and_return('1234')
        # expect_any_instance_of(document_class)
        #   .to receive(:generate_token).exactly(3).times.and_return('1234')
        # expect(d2).to receive(:generate_token).and_return('1234')
        d2 = document.clone
        expect { d2.save }.to raise_exception(Mongoid::Ids::CollisionRetriesExceeded)
        # binding.pry
      end

      it 'should raise an exception when collisions can\'t be resolved on create!' do
        allow_any_instance_of(document_class).to receive(:generate_token).and_return('1234')
        document.save
        expect { document_class.create! }.to raise_exception(Mongoid::Ids::CollisionRetriesExceeded)
      end
    end

    it 'should not raise a custom error if another error is thrown during saving' do
      I18n.enforce_available_locales = false # Supress warnings in this example
      document_class.send(:field, :name)
      document_class.send(:validates_presence_of, :name)
      allow_any_instance_of(document_class).to receive(:generate_token).and_return('1234')
      allow(document_class).to receive(:model_name).and_return(ActiveModel::Name.new(document_class, nil, "temp"))
      expect { document_class.create! }.to raise_exception(Mongoid::Errors::Validations)
    end

    context 'with other unique indexes present' do
      before(:each) do
        document_class.send(:field, :name)
        document_class.send(:index, { name: 1 }, { unique: true })
        document_class.create_indexes
      end

      context 'when violating the other index' do
        it 'should raise an operation failure' do
          duplicate_name = 'Got Duped.'
          document_class.create!(name: duplicate_name)
          expect{ document_class.create!(name: duplicate_name) }
            .to raise_exception(Mongo::Error::OperationFailure)
        end
      end
    end
  end

  describe 'collision resolution on custom field' do
    before(:each) do
      document_class.send(:token, :token)
      document_class.create_indexes
    end

    context 'when creating a new record' do
      it 'should raise  when collisions can\'t be resolved on save' do
        document.token = '1234'
        document.save
        d2 = document.clone
        expect(d2)
          .to receive(:generate_token).exactly(3).times.and_return('1234')
        expect { d2.save }
          .to raise_exception(Mongoid::Ids::CollisionRetriesExceeded)
      end

      it 'should raise when collisions can\'t be resolved on create!' do
        document.token = '1234'
        document.save
        allow_any_instance_of(document_class).to receive(:generate_token).and_return('1234')
        expect { document_class.create! }
          .to raise_exception(Mongoid::Ids::CollisionRetriesExceeded)
      end
    end

    it 'should not raise a custom error if another error is thrown during saving' do
      I18n.enforce_available_locales = false # Supress warnings in this example
      document_class.send(:field, :name)
      document_class.send(:validates_presence_of, :name)
      allow_any_instance_of(document_class).to receive(:generate_token).and_return('1234')
      allow(document_class).to receive(:model_name).and_return(ActiveModel::Name.new(document_class, nil, 'temp'))
      expect{ document_class.create! }
        .to raise_exception(Mongoid::Errors::Validations)
    end

    context 'with other unique indexes present' do
      before(:each) do
        document_class.send(:field, :name)
        document_class.send(:index, { name: 1 }, { unique: true })
        document_class.create_indexes
      end

      context 'when violating the other index' do
        it 'should raise an operation failure' do
          duplicate_name = 'Got Duped.'
          document_class.create!(name: duplicate_name)
          expect{ document_class.create!(name: duplicate_name) }
            .to raise_exception(Mongo::Error::OperationFailure)
        end
      end
    end
  end
end
