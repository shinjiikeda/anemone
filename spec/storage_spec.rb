$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

%w[pstore tokyo_cabinet kyoto_cabinet sqlite3 mongodb redis].each { |file| require "anemone/storage/#{file}.rb" }

module AnemoneKai
  describe Storage do

    describe ".Hash" do
      it "returns a Hash adapter" do
        AnemoneKai::Storage.Hash.should be_an_instance_of(Hash)
      end
    end

    describe ".PStore" do
      it "returns a PStore adapter" do
        test_file = 'test.pstore'
        AnemoneKai::Storage.PStore(test_file).should be_an_instance_of(AnemoneKai::Storage::PStore)
      end
    end

    describe ".TokyoCabinet" do
      it "returns a TokyoCabinet adapter" do
        test_file = 'test.tch'
        store = AnemoneKai::Storage.TokyoCabinet(test_file)
        store.should be_an_instance_of(AnemoneKai::Storage::TokyoCabinet)
        store.close
      end
    end

    describe ".KyotoCabinet" do
      context "when the file is specified" do
        it "returns a KyotoCabinet adapter using that file" do
          test_file = 'test.kch'
          store = AnemoneKai::Storage.KyotoCabinet(test_file)
          store.should be_an_instance_of(AnemoneKai::Storage::KyotoCabinet)
          store.close
        end
      end

      context "when no file is specified" do
        it "returns a KyotoCabinet adapter using the default filename" do
          store = AnemoneKai::Storage.KyotoCabinet
          store.should be_an_instance_of(AnemoneKai::Storage::KyotoCabinet)
          store.close
        end
      end
    end

    describe ".SQLite3" do
      it "returns a SQLite3 adapter" do
        test_file = 'test.db'
        store = AnemoneKai::Storage.SQLite3(test_file)
        store.should be_an_instance_of(AnemoneKai::Storage::SQLite3)
        store.close
      end
    end

    describe ".MongoDB" do
      it "returns a MongoDB adapter" do
        store = AnemoneKai::Storage.MongoDB
        store.should be_an_instance_of(AnemoneKai::Storage::MongoDB)
        store.close
      end
    end

    describe ".MongoDB" do
      it "returns a Redis adapter" do
        store = AnemoneKai::Storage.Redis
        store.should be_an_instance_of(AnemoneKai::Storage::Redis)
        store.close
      end
    end

    module Storage
      shared_examples_for "storage engine" do

        before(:each) do
          @url = SPEC_DOMAIN
          @page = Page.new(URI(@url))
        end

        it "should implement [] and []=" do
          @store.should respond_to(:[])
          @store.should respond_to(:[]=)

          @store[@url] = @page 
          @store[@url].url.should == URI(@url)
        end

        it "should implement has_key?" do
          @store.should respond_to(:has_key?)

          @store[@url] = @page
          @store.has_key?(@url).should == true

          @store.has_key?('missing').should == false
        end

        it "should implement delete" do
          @store.should respond_to(:delete)

          @store[@url] = @page
          @store.delete(@url).url.should == @page.url
          @store.has_key?(@url).should  == false
        end

        it "should implement keys" do
          @store.should respond_to(:keys)

          urls = [SPEC_DOMAIN, SPEC_DOMAIN + 'test', SPEC_DOMAIN + 'another']
          pages = urls.map { |url| Page.new(URI(url)) }
          urls.zip(pages).each { |arr| @store[arr[0]] = arr[1] }

          (@store.keys - urls).should == [] 
        end

        it "should implement each" do
          @store.should respond_to(:each)

          urls = [SPEC_DOMAIN, SPEC_DOMAIN + 'test', SPEC_DOMAIN + 'another']
          pages = urls.map { |url| Page.new(URI(url)) }
          urls.zip(pages).each { |arr| @store[arr[0]] = arr[1] }

          result = {}
          @store.each { |k, v| result[k] = v }
          (result.keys - urls).should == [] 
          (result.values.map { |page| page.url.to_s } - urls).should == []
        end

        it "should implement merge!, and return self" do
          @store.should respond_to(:merge!)

          hash = {SPEC_DOMAIN => Page.new(URI(SPEC_DOMAIN)),
                  SPEC_DOMAIN + 'test' => Page.new(URI(SPEC_DOMAIN + 'test'))}
          merged = @store.merge! hash
          hash.each { |key, value| @store[key].url.to_s.should == key }

          merged.should === @store
        end

        it "should correctly deserialize nil redirect_to when loading" do
          @page.redirect_to.should be_nil
          @store[@url] = @page 
          @store[@url].redirect_to.should be_nil
        end
      end

      describe PStore do
        it_should_behave_like "storage engine"

        before(:each) do
          @test_file = 'test.pstore'
          File.delete @test_file rescue nil
          @store =  AnemoneKai::Storage.PStore(@test_file)
        end

        after(:all) do
          File.delete @test_file rescue nil
        end
      end

      describe TokyoCabinet do
        it_should_behave_like "storage engine"

        before(:each) do
          @test_file = 'test.tch'
          File.delete @test_file rescue nil
          @store =  AnemoneKai::Storage.TokyoCabinet(@test_file)
        end

        after(:each) do
          @store.close
        end

        after(:all) do
          File.delete @test_file rescue nil
        end

        it "should raise an error if supplied with a file extension other than .tch" do
          lambda { AnemoneKai::Storage.TokyoCabinet('test.tmp') }.should raise_error(RuntimeError)
        end
      end

      describe KyotoCabinet do
        it_should_behave_like "storage engine"

        before(:each) do
          @test_file = 'test.kch'
          File.delete @test_file rescue nil
          @store =  AnemoneKai::Storage.KyotoCabinet(@test_file)
        end

        after(:each) do
          @store.close
        end

        after(:all) do
          File.delete @test_file rescue nil
        end

        it "should raise an error if supplied with a file extension other than .kch" do
          lambda { AnemoneKai::Storage.KyotoCabinet('test.tmp') }.should raise_error(RuntimeError)
        end
      end

      describe SQLite3 do
        it_should_behave_like "storage engine"

        before(:each) do
          @test_file = 'test.db'
          File.delete @test_file rescue nil
          @store =  AnemoneKai::Storage.SQLite3(@test_file)
        end

        after(:each) do
          @store.close
        end

        after(:all) do
          File.delete @test_file rescue nil
        end

      end

      describe Storage::MongoDB do
        it_should_behave_like "storage engine"

        before(:each) do
          @store = Storage.MongoDB
        end

        after(:each) do
          @store.close
        end
      end

      describe Storage::Redis do
        it_should_behave_like "storage engine"

        before(:each) do
          @store = Storage.Redis
        end

        after(:each) do
          @store.close
        end
      end

    end
  end
end
