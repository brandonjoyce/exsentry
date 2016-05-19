defmodule ExSentry.ClientTest do
  use ExSpec, async: false
  import Mock
  import ExSentry.Client, only: [capture_exception: 4, capture_message: 3]
  alias ExSentry.Client.State
  doctest ExSentry.Client

  describe "capture_exception" do
    it "dispatches a well-formed request" do
      with_mock ExSentry.Sender, [
        init: fn (_) -> {:ok, :whatever} end,
        send_request: fn (_pid, _url, headers, payload) ->
          assert([] != headers |> Enum.filter(fn ({k,_}) -> k == "X-Sentry-Auth" end))
          assert([] != headers |> Enum.filter(fn ({k,_}) -> k == "Content-Type" end))
          assert("hey" == payload.message)
          assert(%ExSentry.Model.Stacktrace{} = payload.stacktrace)
          :lol
        end
      ] do
        try do
          raise "hey"
        rescue
          e ->
            assert(:lol == capture_exception(e, System.stacktrace, [], %State{}))
        end
      end
    end

    context "when send is disabled" do
      it "skips sending the request" do
        with_mock Application, [:passthrough], [
          get_env: fn(:exsentry, :sender_opts) -> %{disabled: true} end
        ] do
          with_mock ExSentry.Sender, [:passthrough], [
            init: fn (_) -> {:ok, :whatever} end,
            send_request: fn (_pid, _url, _headers, _payload) ->
              raise "This shouldn't be called"
            end
          ] do
            with_mock GenServer, [:passthrough], [
              start_link: fn (ExSentry.Sender, _) -> raise "This shouldn't be called" end,
            ] do
              try do
                raise "hey"
              rescue
                e ->
                  capture_exception(e, System.stacktrace, [], %State{})
              end
            end
          end
        end
      end
    end
  end

  describe "capture_message" do
    it "dispatches a well-formed request" do
      with_mock ExSentry.Sender, [
        init: fn (_) -> {:ok, :whatever} end,
        send_request: fn (_pid, _url, headers, payload) ->
          assert([] != headers |> Enum.filter(fn ({k,_}) -> k == "X-Sentry-Auth" end))
          assert([] != headers |> Enum.filter(fn ({k,_}) -> k == "Content-Type" end))
          assert("hey" == payload.message)
          :lol
        end
      ] do
        assert(:lol == capture_message("hey", [], %State{}))
      end
    end
  end

end

