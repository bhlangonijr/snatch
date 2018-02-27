%%%-------------------------------------------------------------------
%%% @author yan.guiborat
%%% @copyright (C) 2018
%%% @doc
%%%
%%% @end
%%% Created : 08. févr. 2018 10:54
%%%-------------------------------------------------------------------
-module(claws_fcm).
-author("yan.guiborat").

-behaviour(claws).

-export([start_link/2,
         stop/0,
         send/2,
         send/3]).

-spec(start_link(FCMConfig :: map(), NbWorkers :: integer()) ->
  {ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
start_link(FCMConfig, NbWorkers) ->
  application:start(pooler),
  application:start(fxml),
  error_logger:info_msg("~nStarting pool claw with params :~p", [{FCMConfig, NbWorkers}]),
  PoolSpec = [
    {name, push_pool},
    {worker_module, claws_fcm_worker},
    {size, NbWorkers},
    {max_overflow, 10},
    {max_count, 10},
    {init_count, 2},
    {strategy, lifo},
    {start_mfa, {claws_fcm_worker, start_link, [FCMConfig]}},
    {fcm_conf, FCMConfig}
  ],
  pooler:new_pool(PoolSpec),
  {ok, whereis(push_pool)}.

stop() ->
  gen_server:stop(?MODULE).

send(Data, To) ->
  P = pooler:take_member(push_pool),
  gen_statem:cast(P, {send, To, Data}),
  pooler:return_member(push_pool, P, ok).

send(Data, To, _ID) ->
  send(Data, To).
