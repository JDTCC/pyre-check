(*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open OUnit2
open Taint
open TestHelper

let test_dump_model_query_results context =
  let configuration = TaintConfiguration.Heap.default in
  (* Test functions *)
  let _ =
    initialize
      ~models_source:
        {|
      ModelQuery(
        name = "get_foo",
        find = "functions",
        where = name.matches("foo"),
        model = Returns(TaintSource[Test])
      )
      ModelQuery(
        name = "get_bar",
        find = "functions",
        where = name.matches("bar"),
        model = Returns(TaintSource[Test])
      )
      ModelQuery(
        name = "get_fooo",
        find = "functions",
        where = name.matches("fooo"),
        model = Returns(TaintSource[Test])
      )
    |}
      ~context
      ~taint_configuration:configuration
      {|
      def foo1(): ...
      def foo2(): ...
      def bar(): ...
      def barfooo(): ...
      |}
      ~expected_dump_string:
        {|[
  {
    "get_bar": [
      {
        "callable": "test.bar",
        "model": {
          "kind": "model",
          "data": {
            "callable": "test.bar",
            "sources": [
              {
                "port": "result",
                "taint": [
                  { "kinds": [ { "kind": "Test" } ], "decl": null }
                ]
              }
            ],
            "modes": [ "Obscure" ]
          }
        }
      },
      {
        "callable": "test.barfooo",
        "model": {
          "kind": "model",
          "data": {
            "callable": "test.barfooo",
            "sources": [
              {
                "port": "result",
                "taint": [
                  { "kinds": [ { "kind": "Test" } ], "decl": null }
                ]
              }
            ],
            "modes": [ "Obscure" ]
          }
        }
      }
    ]
  },
  {
    "get_foo": [
      {
        "callable": "test.barfooo",
        "model": {
          "kind": "model",
          "data": {
            "callable": "test.barfooo",
            "sources": [
              {
                "port": "result",
                "taint": [
                  { "kinds": [ { "kind": "Test" } ], "decl": null }
                ]
              }
            ],
            "modes": [ "Obscure" ]
          }
        }
      },
      {
        "callable": "test.foo1",
        "model": {
          "kind": "model",
          "data": {
            "callable": "test.foo1",
            "sources": [
              {
                "port": "result",
                "taint": [
                  { "kinds": [ { "kind": "Test" } ], "decl": null }
                ]
              }
            ],
            "modes": [ "Obscure" ]
          }
        }
      },
      {
        "callable": "test.foo2",
        "model": {
          "kind": "model",
          "data": {
            "callable": "test.foo2",
            "sources": [
              {
                "port": "result",
                "taint": [
                  { "kinds": [ { "kind": "Test" } ], "decl": null }
                ]
              }
            ],
            "modes": [ "Obscure" ]
          }
        }
      }
    ]
  },
  {
    "get_fooo": [
      {
        "callable": "test.barfooo",
        "model": {
          "kind": "model",
          "data": {
            "callable": "test.barfooo",
            "sources": [
              {
                "port": "result",
                "taint": [
                  { "kinds": [ { "kind": "Test" } ], "decl": null }
                ]
              }
            ],
            "modes": [ "Obscure" ]
          }
        }
      }
    ]
  }
]|}
  in
  (* Test methods *)
  let _ =
    initialize
      ~models_source:
        {|
        ModelQuery(
          name = "get_Base_child_sources",
          find = "methods",
          where = [cls.matches("Base")],
          model = [
            Parameters(TaintSource[Test], where=index.equals(0)),
          ]
        )
      |}
      ~context
      ~taint_configuration:configuration
      {|
      class Base:
          def foo(self, x):
              return 0
          def baz(self, y):
              return 0
      |}
      ~expected_dump_string:
        {|[
  {
    "get_Base_child_sources": [
      {
        "callable": "test.Base.$class_toplevel",
        "model": {
          "kind": "model",
          "data": { "callable": "test.Base.$class_toplevel" }
        }
      },
      {
        "callable": "test.Base.baz",
        "model": {
          "kind": "model",
          "data": {
            "callable": "test.Base.baz",
            "sources": [
              {
                "port": "formal(self)",
                "taint": [
                  { "kinds": [ { "kind": "Test" } ], "decl": null }
                ]
              }
            ]
          }
        }
      },
      {
        "callable": "test.Base.foo",
        "model": {
          "kind": "model",
          "data": {
            "callable": "test.Base.foo",
            "sources": [
              {
                "port": "formal(self)",
                "taint": [
                  { "kinds": [ { "kind": "Test" } ], "decl": null }
                ]
              }
            ]
          }
        }
      }
    ]
  }
]|}
  in
  (* Test correct ModelQuery<->sources for same callable *)
  let _ =
    initialize
      ~models_source:
        {|
      ModelQuery(
        name = "ModelQueryA",
        find = "functions",
        where = name.matches("foo"),
        model = Returns(TaintSource[Test])
      )
      ModelQuery(
        name = "ModelQueryB",
        find = "functions",
        where = name.matches("foo"),
        model = Returns(TaintSource[UserControlled])
      )
    |}
      ~context
      ~taint_configuration:configuration
      {|
      def foo(x): ...
      |}
      ~expected_dump_string:
        {|[
  {
    "ModelQueryA": [
      {
        "callable": "test.foo",
        "model": {
          "kind": "model",
          "data": {
            "callable": "test.foo",
            "sources": [
              {
                "port": "result",
                "taint": [
                  { "kinds": [ { "kind": "Test" } ], "decl": null }
                ]
              }
            ],
            "modes": [ "Obscure" ]
          }
        }
      }
    ]
  },
  {
    "ModelQueryB": [
      {
        "callable": "test.foo",
        "model": {
          "kind": "model",
          "data": {
            "callable": "test.foo",
            "sources": [
              {
                "port": "result",
                "taint": [
                  { "kinds": [ { "kind": "UserControlled" } ], "decl": null }
                ]
              }
            ],
            "modes": [ "Obscure" ]
          }
        }
      }
    ]
  }
]|}
  in
  (* TODO(T123305678) Add test for attributes *)
  (* Test correct ModelQuery<->sources for same callable *)
  let _ =
    initialize
      ~models_source:
        {|
        ModelQuery(
          name = "get_parent_of_baz_class_sources",
          find = "methods",
          where = [
            cls.any_child(
              cls.matches("Baz"),
              is_transitive=False
            ),
            name.matches("init")
          ],
          model = [
            Parameters(TaintSource[Test], where=[
                Not(name.equals("self")),
                Not(name.equals("a"))
            ])
          ]
        )
        |}
      ~context
      ~taint_configuration:configuration
      {|
      class Foo:
        def __init__(self, a, b):
          ...
      class Bar(Foo):
        def __init__(self, a, b):
          ...
      class Baz(Bar):
        def __init__(self, a, b):
          ...
      |}
      ~expected_dump_string:
        {|[
  {
    "get_parent_of_baz_class_sources": [
      {
        "callable": "test.Bar.__init__",
        "model": {
          "kind": "model",
          "data": {
            "callable": "test.Bar.__init__",
            "sources": [
              {
                "port": "formal(b)",
                "taint": [
                  { "kinds": [ { "kind": "Test" } ], "decl": null }
                ]
              }
            ],
            "modes": [ "Obscure" ]
          }
        }
      },
      {
        "callable": "test.Baz.__init__",
        "model": {
          "kind": "model",
          "data": {
            "callable": "test.Baz.__init__",
            "sources": [
              {
                "port": "formal(b)",
                "taint": [
                  { "kinds": [ { "kind": "Test" } ], "decl": null }
                ]
              }
            ],
            "modes": [ "Obscure" ]
          }
        }
      }
    ]
  }
]|}
  in
  let _ =
    initialize
      ~models_source:
        {|
        ModelQuery(
          name = "get_parent_of_baz_class_transitive_sources",
          find = "methods",
          where = [
            cls.any_child(
              AnyOf(
                cls.decorator(
                  name.matches("anything")
                ),
                AllOf(
                  Not(cls.matches("Foo")),
                  Not(cls.matches("Bar")),
                )
              ),
              is_transitive=True
            ),
            name.matches("init")
          ],
          model = [
            Parameters(TaintSource[Test], where=[
                Not(name.equals("self")),
                Not(name.equals("a"))
            ])
          ]
        )
        |}
      ~context
      ~taint_configuration:configuration
      {|
      class Foo:
        def __init__(self, a, b):
          ...
      class Bar(Foo):
        def __init__(self, a, b):
          ...
      class Baz(Bar):
        def __init__(self, a, b):
          ...
      |}
      ~expected_dump_string:
        {|[
  {
    "get_parent_of_baz_class_transitive_sources": [
      {
        "callable": "test.Bar.__init__",
        "model": {
          "kind": "model",
          "data": {
            "callable": "test.Bar.__init__",
            "sources": [
              {
                "port": "formal(b)",
                "taint": [
                  { "kinds": [ { "kind": "Test" } ], "decl": null }
                ]
              }
            ],
            "modes": [ "Obscure" ]
          }
        }
      },
      {
        "callable": "test.Baz.__init__",
        "model": {
          "kind": "model",
          "data": {
            "callable": "test.Baz.__init__",
            "sources": [
              {
                "port": "formal(b)",
                "taint": [
                  { "kinds": [ { "kind": "Test" } ], "decl": null }
                ]
              }
            ],
            "modes": [ "Obscure" ]
          }
        }
      },
      {
        "callable": "test.Foo.__init__",
        "model": {
          "kind": "model",
          "data": {
            "callable": "test.Foo.__init__",
            "sources": [
              {
                "port": "formal(b)",
                "taint": [
                  { "kinds": [ { "kind": "Test" } ], "decl": null }
                ]
              }
            ],
            "modes": [ "Obscure" ]
          }
        }
      }
    ]
  }
]|}
  in

  ()


let () =
  "dump_model_query_results"
  >::: ["dump_model_query_results" >:: test_dump_model_query_results]
  |> Test.run
